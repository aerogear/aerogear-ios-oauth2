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

import AeroGearHttp
public typealias SuccessType = AnyObject?->()
public typealias FailureType = NSError->()

public let AGAppLaunchedWithURLNotification = "AGAppLaunchedWithURLNotification"
public let AGAppDidBecomeActiveNotification = "AGAppDidBecomeActiveNotification"
let AGAuthzErrorDomain = "AGAuthzErrorDomain"


enum AuthorizationState {
    case AuthorizationStatePendingExternalApproval
    case AuthorizationStateApproved
    case AuthorizationStateUnknown
}

public class OAuth2Module {
    let config: Config
    var httpSession: Session
    var oauth2Session: OAuth2Session
    var applicationLaunchNotificationObserver: NSObjectProtocol?
    var applicationDidBecomeActiveNotificationObserver: NSObjectProtocol?
    var state: AuthorizationState
    
    // used without AccountManager, default accountId, not really usefull
    public convenience init(config:Config) {
        if (config.accountId != nil) {
            self.init(config: config, accountId:config.accountId!)
        } else {
            self.init(config: config, accountId:"ACCOUNT_FOR_CLIENTID_\(config.clientId)")
        }
    }
    
    // used by AccountManager with a user given accountId
    public init(config:Config, accountId: String) {
        self.config = config
        // TODO use timeout config paramter
        self.httpSession = Session(url: config.base, sessionConfig: NSURLSessionConfiguration.defaultSessionConfiguration())
        self.oauth2Session = OAuth2Session(accountId:accountId)
        self.state = .AuthorizationStateUnknown
    }
    
    // MARK: Public API - To be overriden if necessary by OAuth2 specific adapter
    
    public func requestAuthorizationCodeSuccess(success:SuccessType, failure:FailureType) {
        
        let urlString = self.urlAsString();
        println("URL==\(urlString)")
        
        let url = NSURL(string: urlString)
        
        //let url = NSURL(string:"\(config.authzEndpointURL.absoluteString!)?scope=\(config.scopes)&redirect_uri=\(config.redirectURL)&client_id=\(config.clientId)&response_type=code")
        
        println("\(config.authzEndpointURL.absoluteString!)?scope=\(config.scopes)&redirect_uri=\(config.redirectURL)&client_id=\(config.clientId)&response_type=code")
        println("URL:\(url.absoluteString!)")
        // register with the notification system in order to be notified when the 'authorization' process completes in the
        // external browser, and the oauth code is available so that we can then proceed to request the 'access_token'
        // from the server.
        applicationLaunchNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AGAppLaunchedWithURLNotification, object:nil, queue:nil, usingBlock: { (notification: NSNotification!) -> Void in
            self.extractCode(notification, success:success, failure:failure)
        })
        
        // register to receive notification when the application becomes active so we
        // can clear any pending authorization requests which are not completed properly,
        // that is a user switched into the app without Accepting or Cancelling the authorization
        // request in the external browser process.
        applicationDidBecomeActiveNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AGAppDidBecomeActiveNotification, object:nil, queue:nil, usingBlock: { (note: NSNotification!) -> Void in
            // check the state
            if (self.state == .AuthorizationStatePendingExternalApproval) {
                // unregister
                self.stopObserving()
                // ..and update state
                self.state = .AuthorizationStateUnknown;
            }
        })
        
        // update state to 'Pending'
        self.state = .AuthorizationStatePendingExternalApproval
        
        UIApplication.sharedApplication().openURL(url);
    }
    
    public func refreshAccessTokenSuccess(success:SuccessType, failure:FailureType) {
    }
    
    public func exchangeAuthorizationCodeForAccessToken(code: String, success:SuccessType, failure:FailureType) {
        
    }
    
    public func requestAccessSuccess(success:SuccessType, failure:FailureType) {
        if (self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()) {
            // we already have a valid access token, nothing more to be done
            success(self.oauth2Session.accessToken!);
        } else if (self.oauth2Session.refreshToken != nil) {
            // need to refresh token
            self.refreshAccessTokenSuccess(success, failure:failure);
        } else {
            // ask for authorization code and once obtained exchange code for access token
            self.requestAuthorizationCodeSuccess(success, failure:failure);
        }
    }
    
    public func revokeAccessSuccess(success:SuccessType, failure:FailureType) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return;
        }
        let paramDict:[String:String] = ["token":self.oauth2Session.accessToken!]
        httpSession.baseURL = config.revokeTokenEndpointURL!
        
        httpSession.POST(parameters: paramDict, success: { (param: AnyObject?) -> () in
            self.oauth2Session.saveAccessToken()
            success(param!)
            }, failure: { (error: NSError) -> () in
                failure(error)
        })
        
    }
    
    
    // MARK: Internal Methods
    
    func extractCode(notification:NSNotification, success:AnyObject->(), failure:NSError->()) {
    }
    
    deinit {
        self.stopObserving()
    }
    
    func stopObserving() {
        // clear all observers
        if (applicationLaunchNotificationObserver != nil) {
            NSNotificationCenter.defaultCenter().removeObserver(applicationLaunchNotificationObserver!)
            self.applicationLaunchNotificationObserver = nil;
        }
        
        if (applicationDidBecomeActiveNotificationObserver != nil) {
            NSNotificationCenter.defaultCenter().removeObserver(applicationDidBecomeActiveNotificationObserver!)
            applicationDidBecomeActiveNotificationObserver = nil
        }
    }
    
    func authorizationFields() -> [String:Any]? {
        if (self.oauth2Session.accessToken == nil) {
            return nil
        } else {
            return ["Authorization":"Bearer \(self.oauth2Session.accessToken!)"]
        }
    }
    
    func isAuthorized() -> Bool {
        return self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()
    }
    
    func urlAsString() -> String {
        let scope = self.scope()
        let urlRedirect = self.urlEncodeString(config.redirectURL)
        let url = "\(config.authzEndpointURL.absoluteString!)?scope=\(scope)&redirect_uri=\(urlRedirect)&client_id=\(config.clientId)&response_type=code"
        return url
    }
    
    func scope() -> String {
        // Create a string to concatenate all scopes existing in the _scopes array.
        var scopeString = ""
        for scope in config.scopes {
            scopeString += self.urlEncodeString(scope)
            // If the current scope is other than the last one, then add the "+" sign to the string to separate the scopes.
            if (scope != config.scopes.last) {
                scopeString += "+"
            }
        }
        return scopeString
    }
    
    func urlEncodeString(stringToURLEncode:String) -> String {
        let encodedURL = CFURLCreateStringByAddingPercentEscapes(nil,
            stringToURLEncode as NSString,
            nil,
            "!@#$%&*'();:=+,/?[]",
            CFStringBuiltInEncodings.UTF8.toRaw())
        return encodedURL as NSString
    }
}
