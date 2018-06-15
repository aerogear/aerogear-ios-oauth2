/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import UIKit
import AeroGearHttp
import JWT
import SafariServices
import WebKit

/**
Notification constants emitted during oauth authorization flow.
*/
public let AGAppLaunchedWithURLNotification = "AGAppLaunchedWithURLNotification"
public let AGAppDidBecomeActiveNotification = "AGAppDidBecomeActiveNotification"
public let AGAuthzErrorDomain = "AGAuthzErrorDomain"

/**
The current state that this module is in.

- authorizationStatePendingExternalApproval: the module is waiting external approval.
- authorizationStateApproved: the oauth flow has been approved.
- authorizationStateUnknown: the oauth flow is in unknown state (e.g. user clicked cancel).
*/
enum AuthorizationState {
    case authorizationStatePendingExternalApproval
    case authorizationStateApproved
    case authorizationStateUnknown
}

public enum OAuth2Error: Error {
    case MissingRefreshToken
    case UnexpectedResponse(String)
    case UnequalStateParameter(String)
}

public enum BrowserType {
    case webView
    case safariViewController
    case safariAuthenticationSession
    case safariExternalBrowser
    case unknown

    var description : String {
        switch self {
        case .webView: return "web-view";
        case .safariViewController: return "safari-view-controller";
        case .safariAuthenticationSession: return "safari-authentication-session";
        case .safariExternalBrowser: return "safari-external-browser";
        case .unknown: return "unknown";
        }
    }
}

fileprivate extension UIApplication {
    var tdcTopViewController: UIViewController? {
        guard let rootViewController = keyWindow?.rootViewController else {
            return nil
        }

        var pointedViewController: UIViewController? = rootViewController

        while  pointedViewController?.presentedViewController != nil {
            switch pointedViewController?.presentedViewController {
            case let navagationController as UINavigationController:
                pointedViewController = navagationController.viewControllers.last
            case let tabBarController as UITabBarController:
                pointedViewController = tabBarController.selectedViewController
            default:
                pointedViewController = pointedViewController?.presentedViewController
            }
        }

        return pointedViewController
    }
}


/**
Parent class of any OAuth2 module implementing generic OAuth2 authorization flow.
*/
open class OAuth2Module: NSObject, AuthzModule, SFSafariViewControllerDelegate {
    
    open let config: Config
    let jsonResponseSerializerWithDate: JsonResponseSerializerWithDate?
    open var http: Http
    open var oauth2Session: OAuth2Session
    var applicationLaunchNotificationObserver: NSObjectProtocol?
    var applicationDidBecomeActiveNotificationObserver: NSObjectProtocol?
    var state: AuthorizationState
    var browserType: BrowserType
    var authenticationSession: Any? // We need this optional on the object otherwise the popup dialog disappears immediately. It has to be an Any instead of a SFAuthenticationSession because SFAuthenticationSession is only available in iOS 11+ and we do not want to mark the whole class with `@available(iOS 11.0, *)` and we can't use that syntax on stored properties.
    var urlsForHE: [String]?
    var logSessionId: String?
    var advertisingId: String?
    var analyticsEndpoint: String?
    var tsSdkInitiliazation: Int64?
    var tsLoginButtonClicked: Int64?
    var tsRedirectUrlInvoked: Int64?
    var tsTokenResponseReceived: Int64?

    /**
    Initialize an OAuth2 module.

    :param: config the configuration object that setups the module.
    :param: session the session that that module will be bound to.
    :param: requestSerializer the actual request serializer to use when performing requests.
    :param: responseSerializer the actual response serializer to use upon receiving a response.

    :returns: the newly initialized OAuth2Module.
    */
    public required init(config: Config, session: OAuth2Session? = nil, requestSerializer: RequestSerializer = HttpRequestSerializer(), responseSerializer: ResponseSerializer = JsonResponseSerializerWithDate()) {
        self.tsSdkInitiliazation = Int64(NSDate().timeIntervalSince1970 * 1000);
        self.advertisingId = "";
        self.jsonResponseSerializerWithDate = responseSerializer as? JsonResponseSerializerWithDate

        if (config.accountId == nil) {
            config.accountId = "ACCOUNT_FOR_CLIENTID_\(config.clientId)"
        }
        if (session == nil) {
            self.oauth2Session = TrustedPersistentOAuth2Session(accountId: config.accountId!)
        } else {
            self.oauth2Session = session!
        }

        if (config.optionalParams == nil) {
            config.optionalParams = [String: String]();
        }

        self.config = config
        
        self.http = Http(baseURL: config.baseURL, requestSerializer: requestSerializer, responseSerializer:  responseSerializer)
        self.state = .authorizationStateUnknown
        self.browserType = .unknown;

        super.init()

        ForcedHEManager.initForcedHE()
        self.fetchWellknownConfig()
    }

    func fetchWellknownConfig() {
        self.http.request(method: .get, path: config.wellKnownConfigurationEndpoint!, completionHandler: { (response, error) in
            guard let unwrappedResponse = response as? [String: AnyObject], error == nil else {
                return
            }
            if let heUrls = unwrappedResponse["network_authentication_target_urls"] as? [String] {
                ForcedHEManager.setHEUrls(Set<String>(heUrls))
            }
            if let analyticsEndpoint = unwrappedResponse["telenordigital_sdk_analytics_endpoint"] as? String {
                self.analyticsEndpoint = analyticsEndpoint + "/V1/ios";
            }
        });
    }

    func getBrowserTypeToUse() -> BrowserType {
        if self.config.isWebView {
            return .webView;
        }
        if #available(iOS 11.0, *) {
            return .safariAuthenticationSession;
        }
        if #available(iOS 9.0, *) {
            return .safariViewController;
        }
        return .safariExternalBrowser;
    }

    // MARK: Public API - To be overriden if necessary by OAuth2 specific adapter
    
    /**
    Request an authorization code.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func requestAuthorizationCode(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        let state = NSUUID().uuidString
        // register to receive notification when the application becomes active so we
        // can clear any pending authorization requests which are not completed properly,
        // that is a user switched into the app without Accepting or Cancelling the authorization
        // request in the external browser process.
        applicationDidBecomeActiveNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AGAppDidBecomeActiveNotification), object:nil, queue:nil, using: { (note: Notification!) -> Void in
            // check the state
            if (self.state == .authorizationStatePendingExternalApproval) {
                // unregister
                self.stopObserving()
                // ..and update state
                self.state = .authorizationStateUnknown
            }
        })

        // update state to 'Pending'
        self.state = .authorizationStatePendingExternalApproval

        // get the user agent we will use for authentication
        self.browserType = getBrowserTypeToUse();

        self.logSessionId = NSUUID().uuidString

        let useForcedHeaderInjection = browserType == .webView && ForcedHEManager.isCellularEnabled() && ForcedHEManager.isWifiEnabled();
        if (!ForcedHEManager.isCellularEnabled()) {
            config.optionalParams!["prompt"] = "no_seam";
        }
        if (useForcedHeaderInjection) {
            let mccMnc:String = OperatorInfo.id()
            config.optionalParams!["login_hint"] = "MCCMNC:" + mccMnc;
            URLProtocol.registerClass(ForcedHEURLProtocol.self)
        }

        // calculate final url
        var url: URL
        do {
            url = try OAuth2Module.getAuthUrl(config: config, http: http, state: state, logSessionId: logSessionId, browserType: browserType)
        } catch let error as NSError {
            completionHandler(nil, error)
            return
        }
        
        // register with the notification system in order to be notified when the 'authorization' process completes in the
        // external browser, and the oauth code is available so that we can then proceed to request the 'access_token'
        // from the server.
        applicationLaunchNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AGAppLaunchedWithURLNotification), object: nil, queue: nil, using: { (notification: Notification!) -> Void in
            let info = notification.userInfo!
            let url: URL? = info[UIApplicationLaunchOptionsKey.url] as? URL
            self.handleCallback(url, error: nil, state: state, completionHandler: completionHandler)
        })

        if browserType == .webView || browserType == .unknown {
            let webViewController = OAuth2WebViewController()
            webViewController.targetURL = url;
            UIApplication.shared.tdcTopViewController?.present(webViewController, animated: true, completion: nil)
        } else if browserType == .safariAuthenticationSession {
            if #available(iOS 11.0, *) {
                self.authenticationSession = SFAuthenticationSession(url: url, callbackURLScheme: nil, completionHandler: { (successUrl: URL?, error: Error?) in
                    self.handleCallback(successUrl, error: error, state: state, completionHandler: completionHandler)
                })
                (self.authenticationSession as! SFAuthenticationSession).start()
            }
        } else if browserType == .safariViewController {
            if #available(iOS 9.0, *) {
                let safariViewController = SFSafariViewController(url: url as URL)
                safariViewController.delegate = self
                UIApplication.shared.tdcTopViewController?.present(safariViewController, animated: true, completion: nil)
            }
        } else if browserType == .safariExternalBrowser {
            UIApplication.shared.openURL(url as URL)
        }
    }
    
    func handleCallback(_ successUrl: URL?, error: Error?, state: String, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        guard let successUrl = successUrl, error == nil else {
            self.callCompletion(success: nil, error: error as NSError?, completionHandler: completionHandler)
            return
        }
        
        let stateFromRedirectUrl = self.parametersFrom(queryString: successUrl.query)["state"]
        
        if stateFromRedirectUrl != state {
            let error = OAuth2Error.UnequalStateParameter("The state parameter in the redirect url was not the same as the one sent to the auth server.") as NSError
            self.callCompletion(success: nil, error: error, completionHandler: completionHandler)
            return
        }
        
        self.extractCode(fromUrl: successUrl, completionHandler: { (accessToken: AnyObject?, error: NSError?) in
            self.callCompletion(success: accessToken, error: error, completionHandler: completionHandler)
        })
    }
    
    func callCompletion(success: AnyObject?, error: NSError?, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        if browserType == .safariViewController || browserType == .webView {
            UIApplication.shared.tdcTopViewController?.dismiss( animated: true, completion: {
                completionHandler(success, error)
            })
        } else {
            completionHandler(success, error)
        }
    }
    
    public class func getAuthUrl(config: Config, http: Http, state: String? = nil, logSessionId: String? = nil, browserType: BrowserType) throws -> URL {
        let optionalParamsEncoded = config.optionalParams?.keys.reduce("", { (current: String, key: String) -> String in
            return "\(current)&\(key.urlEncode())=\(config.optionalParams![key]!.urlEncode())"
        })
        
        var version = "unknown"
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist", inDirectory: "Frameworks/TDConnectIosSdk.framework") {
            if let dict = NSDictionary(contentsOfFile: path) {
                let osVersion = ProcessInfo.processInfo.operatingSystemVersion
                let podVersion = dict["CFBundleShortVersionString"] as! String
                let browserTypeDesc = browserType.description;
                version = "v\(podVersion)_\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)_\(browserTypeDesc)"
            }
        }

        var params = "?scope=\(config.scopesEncoded)&redirect_uri=\(config.redirectURL.urlEncode())&client_id=\(config.clientId)&response_type=code&telenordigital_sdk_version=ios_\(version)"
        if let optionalParamsEncoded = optionalParamsEncoded {
            params += optionalParamsEncoded
        }
        
        if let claims = config.claims {
            do {
                try params += OAuth2Module.getParam(claims: claims)
            } catch {
                throw error
            }
        }
        
        if let state = state {
            params += "&state=\(state)"
        }

        if let lsi = logSessionId {
            params += "&log_session_id=\(lsi)"
        }
        
        guard let computedUrl = http.calculateURL(baseURL: config.baseURL, url:config.authzEndpoint) else {
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "Malformatted URL."])
            throw error
        }
        
        return URL(string:computedUrl.absoluteString + params)!
    }
    
    public class func getParam(claims: Set<String>) throws -> String {
        let essentialClaims = claims.reduce([:], { (current: [String: Any], claim: String) -> [String: Any] in
            var newCurrent = current
            newCurrent[claim] = ["essential": true]
            return newCurrent
        })
        
        let userinfoClaims = [
            "userinfo" : essentialClaims
        ]
        
        var jsonClaims: Data
        do {
            jsonClaims = try JSONSerialization.data(withJSONObject: userinfoClaims, options: JSONSerialization.WritingOptions()) as Data
        } catch let error as NSError {
            print(error)
            throw error
        }
       
        let jsonClaimsString = NSString(data: jsonClaims as Data, encoding: String.Encoding.utf8.rawValue)
        let encodedJson = (jsonClaimsString! as String).urlEncode()
        return "&claims=\(encodedJson)"
    }

    /**
    Request to refresh an access token.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func refreshAccessToken(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        guard let unwrappedRefreshToken = self.oauth2Session.refreshToken else {
            completionHandler(nil, OAuth2Error.MissingRefreshToken as NSError)
            return
        }

        var paramDict: [String: String] = ["refresh_token": unwrappedRefreshToken, "client_id": config.clientId, "grant_type": "refresh_token"]
        if (config.clientSecret != nil) {
            paramDict["client_secret"] = config.clientSecret!
        }
        
        http.request(method: .post, path: config.refreshTokenEndpoint!, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in
            if (error != nil) {
                if error?.code == 400 {
                    self.oauth2Session.clearTokens()
                }
                
                completionHandler(nil, error)
                return
            }
            
            guard let unwrappedResponse = response as? [String: AnyObject] else {
                completionHandler(nil, OAuth2Error.UnexpectedResponse(response as! String) as NSError)
                return
            }
            
            let accessToken: String = unwrappedResponse["access_token"] as! String
            let expiration = unwrappedResponse["expires_in"] as! NSNumber
            let exp: String = expiration.stringValue
            var refreshToken = unwrappedRefreshToken
            if let newRefreshToken = unwrappedResponse["refresh_token"] as? String {
                refreshToken = newRefreshToken
            }
            
            self.oauth2Session.save(accessToken: accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: nil, idToken: nil)
            
            completionHandler(unwrappedResponse["access_token"], nil);
        })
    }

    func sendAnalyticsData(accessToken: String?, subjectId: String?) {
        guard let analyticsEndpoint = self.analyticsEndpoint else {
            return
        }

        var paramDict = [String: String]()

        if let logSessionId = self.logSessionId {
            paramDict["log_session_id"] = logSessionId
        }
        if let advertisingId = self.advertisingId {
            paramDict["advertisingId"] = advertisingId
        }
        if let tsSdkInitiliazation = self.tsSdkInitiliazation {
            paramDict["tsSdkInitiliazation"] = String(tsSdkInitiliazation);
        }
        if let tsLoginButtonClicked = self.tsLoginButtonClicked {
            paramDict["tsLoginButtonClicked"] = String(tsLoginButtonClicked)
        }
        if let tsRedirectUrlInvoked = self.tsRedirectUrlInvoked {
            paramDict["tsRedirectUrlInvoked"] = String(tsRedirectUrlInvoked)
        }
        if let tsTokenResponseReceived = self.tsTokenResponseReceived {
            paramDict["tsTokenResponseReceived"] = String(tsTokenResponseReceived)
        }
        if let subjectId = subjectId {
            paramDict["subject"] = subjectId
        }
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            paramDict["appName"] = appName
        }
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            paramDict["appVersion"] = appVersion
        }

        paramDict["deviceName"] = UIDevice.current.name
        paramDict["deviceModel"] = UIDevice.current.modelName
        paramDict["osName"] = UIDevice.current.systemName
        paramDict["osVersion"] = UIDevice.current.systemVersion

        let http = Http()
        if accessToken != nil {
            http.authzModule = self
        }
        http.request(method: .post, path: analyticsEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in
        })
    }

    /**
    Exchange an authorization code for an access token.

    :param: code the 'authorization' code to exchange for an access token.
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        var paramDict: [String: String] = ["code": code, "client_id": config.clientId, "redirect_uri": config.redirectURL, "grant_type":"authorization_code"]

        if let unwrapped = config.clientSecret {
            paramDict["client_secret"] = unwrapped
        }

        self.tsRedirectUrlInvoked = Int64(NSDate().timeIntervalSince1970 * 1000);

        http.request(method: .post, path: config.accessTokenEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: {(responseObject, error) in
            self.tsTokenResponseReceived = Int64(NSDate().timeIntervalSince1970 * 1000);

            if (error != nil) {
                self.sendAnalyticsData(accessToken: nil, subjectId: nil)
                completionHandler(nil, error)
                return
            }

            guard let unwrappedResponse = responseObject as? [String: AnyObject] else {
                self.sendAnalyticsData(accessToken: nil, subjectId: nil)
                completionHandler(nil, OAuth2Error.UnexpectedResponse(responseObject as! String) as NSError)
                return
            }
            
            let accessToken: String = unwrappedResponse["access_token"] as! String
            let refreshToken: String? = unwrappedResponse["refresh_token"] as? String
            let idToken: String? = unwrappedResponse["id_token"] as? String
            let expiration = unwrappedResponse["expires_in"] as? NSNumber
            let exp: String? = expiration?.stringValue
            // expiration for refresh token is used in Keycloak
            let expirationRefresh = unwrappedResponse["refresh_expires_in"] as? NSNumber
            let expRefresh = expirationRefresh?.stringValue
            
            if idToken != nil {
                let error = self.validateJwtIdToken(idToken: idToken!)
                if (error != nil) {
                    self.sendAnalyticsData(accessToken: accessToken, subjectId: nil)
                    completionHandler(nil, error! as NSError)
                    return
                }
            }

            self.oauth2Session.save(accessToken: accessToken,
                refreshToken: refreshToken,
                accessTokenExpiration: exp,
                refreshTokenExpiration: expRefresh,
                idToken: idToken)

            let idTokenPayload = self.getIdTokenPayload()
            let subjectId = idTokenPayload?["sub"] as? String
            self.sendAnalyticsData(accessToken: accessToken, subjectId: subjectId)

            completionHandler(accessToken as AnyObject?, nil)
        })
    }

    /**
    Gateway to request authorization access.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        if (self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()) {
            // we already have a valid access token, nothing more to be done
            completionHandler(self.oauth2Session.accessToken! as AnyObject?, nil)
        } else if (self.oauth2Session.refreshToken != nil && self.oauth2Session.refreshTokenIsNotExpired()) {
            // need to refresh token
            self.refreshAccessToken(completionHandler: completionHandler)
        } else {
            self.tsLoginButtonClicked = Int64(NSDate().timeIntervalSince1970 * 1000);
            // ask for authorization code and once obtained exchange code for access token
            self.requestAuthorizationCode(completionHandler: completionHandler)
        }
    }

    /**
    Gateway to provide authentication using the Authorization Code Flow with OpenID Connect.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func login(completionHandler: @escaping (AnyObject?, OpenIdClaim?, NSError?) -> Void) {

        self.requestAccess { (response: AnyObject?, error: NSError?) -> Void in

            if (error != nil) {
                completionHandler(nil, nil, error)
                return
            }
            
            var paramDict: [String: String] = [:]
            if response != nil {
                paramDict = ["access_token": response! as! String]
            }

            guard let userInfoEndpoint = self.config.userInfoEndpoint else {
                completionHandler(nil, nil, NSError(domain: "OAuth2Module", code: 0, userInfo: ["OpenID Connect" : "No UserInfo endpoint available in config"]))
                return
            }

            let http = Http(baseURL: self.config.baseURL)
            http.authzModule = self
            // http.request(.GET, path:userInfoEndpoint, completionHandler: {(responseObject, error) in
            self.http.request(method: .get, path:userInfoEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: {(responseObject, error) in
                if (error != nil) {
                    completionHandler(nil, nil, error)
                    return
                }
                var openIDClaims: OpenIdClaim?
                if let unwrappedResponse = responseObject as? [String: AnyObject] {
                    openIDClaims = self.makeOpenIdClaim(fromDict: unwrappedResponse)
                }
                completionHandler(response, openIDClaims, nil)
            })

        }

    }

    open func makeOpenIdClaim(fromDict: [String: AnyObject]) -> OpenIdClaim {
        return OpenIdClaim(fromDict: fromDict)
    }

    /**
    Request to revoke access.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return
        }
        let paramDict: [String:String] = ["token":self.oauth2Session.accessToken!]

        http.request(method: .post, path: config.revokeTokenEndpoint!, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }

            self.oauth2Session.clearTokens()
            completionHandler(response as AnyObject?, nil)
        })
    }

    /**
    Return any authorization fields.

    :returns:  a dictionary filled with the authorization fields.
    */
    open func authorizationFields() -> [String: String]? {
        if (self.oauth2Session.accessToken == nil) {
            return nil
        } else {
            return ["Authorization":"Bearer \(self.oauth2Session.accessToken!)"]
        }
    }

    /**
    Returns a boolean indicating whether authorization has been granted.

    :returns: true if authorized, false otherwise.
    */
    open func isAuthorized() -> Bool {
        return self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()
    }
    
    func extractCode(fromUrl url: URL?, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // extract the code from the URL
        let code = self.parametersFrom(queryString: url?.query)["code"]
        // if exists perform the exchange
        if (code != nil && self.config.isPublicClient) {
            self.exchangeAuthorizationCodeForAccessToken(code: code!, completionHandler: completionHandler)
            // update state
            state = .authorizationStateApproved
        } else if (code != nil && !self.config.isPublicClient) {
            completionHandler(code! as AnyObject?, nil)
            state = .authorizationStateApproved
        } else {
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "User cancelled authorization."])
            completionHandler(nil, error)
        }
        // finally, unregister
        self.stopObserving()
    }

    func parametersFrom(queryString: String?) -> [String: String] {
        var parameters = [String: String]()
        guard let queryString = queryString else {
            return parameters
        }

        let parameterScanner: Scanner = Scanner(string: queryString)
        var name: NSString? = nil
        var value: NSString? = nil

        while (parameterScanner.isAtEnd != true) {
            name = nil
            parameterScanner.scanUpTo("=", into: &name)
            parameterScanner.scanString("=", into:nil)

            value = nil
            parameterScanner.scanUpTo("&", into:&value)
            parameterScanner.scanString("&", into:nil)

            if (name != nil && value != nil) {
                parameters[name!.removingPercentEncoding!] = value!.removingPercentEncoding
            }
        }

        return parameters
    }
    
    public func getIdTokenPayload() -> Payload? {
        guard let signedJwt = oauth2Session.idToken else {
            return nil
        }

        return try? JWT.decode(signedJwt, algorithm: .none, verify: false, audience: config.clientId, issuer: config.baseURL)
    }
    
    public func validateJwtIdToken(idToken: String) -> Error? {
        var token: Payload
        do {
            token = try JWT.decode(idToken, algorithm: .none, verify: false, audience: self.config.clientId, issuer: self.config.baseURL)
        } catch {
            return error
        }
        
        let serverTime = self.jsonResponseSerializerWithDate?.lastServerTime
        return validateIdToken(token: token as [String : AnyObject], expectedIssuer: self.config.baseURL, expectedAudience: self.config.clientId, serverTime: serverTime)
    }
    
    public func getIdTokenEncoded() -> String? {
        return oauth2Session.idToken
    }

    deinit {
        self.stopObserving()
    }

    func stopObserving() {
        // clear all observers
        if (applicationLaunchNotificationObserver != nil) {
            NotificationCenter.default.removeObserver(applicationLaunchNotificationObserver!)
            self.applicationLaunchNotificationObserver = nil
        }

        if (applicationDidBecomeActiveNotificationObserver != nil) {
            NotificationCenter.default.removeObserver(applicationDidBecomeActiveNotificationObserver!)
            applicationDidBecomeActiveNotificationObserver = nil
        }
    }
    
    @available(iOS 9.0, *)
    public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        stopObserving()
    }
}
