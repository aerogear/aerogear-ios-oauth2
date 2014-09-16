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

public class FacebookConfig: Config {
    public init(clientId: String, clientSecret: String, scopes: [String], accountId: String? = nil) {
        super.init(base: "",
            authzEndpoint: "https://www.facebook.com/dialog/oauth",
            redirectURL: "fb\(clientId)://authorize/",
            accessTokenEndpoint: "https://graph.facebook.com/oauth/access_token",
            clientId: clientId,
            clientSecret: clientSecret,
            revokeTokenEndpoint: "https://www.facebook.com/me/permissions",
            scopes: scopes,
            accountId: accountId)
    }
}

public class GoogleConfig: Config {
    public init(clientId: String, scopes: [String], accountId: String? = nil) {
        let bundleString = NSBundle.mainBundle().bundleIdentifier!
        super.init(base: "https://accounts.google.com",
            authzEndpoint: "o/oauth2/auth",
            redirectURL: "\(bundleString):/oauth2Callback",
            accessTokenEndpoint: "o/oauth2/token",
            clientId: clientId,
            revokeTokenEndpoint: "rest/revoke",
            scopes: scopes,
            accountId: accountId)
    }
}

public class AccountManager {
    
    var modules: [String: OAuth2Module]
    
    init() {
        self.modules = [String: OAuth2Module]()
    }
    
    public class var sharedInstance: AccountManager {
        struct Singleton {
            static let instance = AccountManager()
        }
        return Singleton.instance
    }
    
    public class func addAccount(config: Config, moduleClass: OAuth2Module.Type) -> OAuth2Module {
        var myModule:OAuth2Module
        myModule = moduleClass(config: config)
        // TODO check accountId is unique in modules list
        sharedInstance.modules[myModule.oauth2Session.accountId] = myModule
        return myModule
    }
    
    public class func removeAccount(name: String, config: Config, moduleClass: OAuth2Module.Type) -> OAuth2Module? {
        return sharedInstance.modules.removeValueForKey(name)
    }
    
    public class func getAccountByName(name: String) -> OAuth2Module? {
        return sharedInstance.modules[name]
    }
    
    public class func getAccountsByClienId(clientId: String) -> [OAuth2Module] {
        let modules: [OAuth2Module] = [OAuth2Module](sharedInstance.modules.values)
        return modules.filter {$0.config.clientId == clientId }
    }

    public class func getAccountByConfig(config: Config) -> OAuth2Module? {
        if config.accountId != nil {
            return sharedInstance.modules[config.accountId!]
        } else {
            let modules = getAccountsByClienId(config.clientId)
            if modules.count > 0 {
                return modules[0]
            } else {
                return nil
            }
        }
    }

    public class func addFacebookAccount(config: FacebookConfig) -> FacebookOAuth2Module {
        return addAccount(config, moduleClass: FacebookOAuth2Module.self) as FacebookOAuth2Module
    }
    
    public class func addGoogleAccount(config: GoogleConfig) -> OAuth2Module {
        return addAccount(config, moduleClass: OAuth2Module.self)
    }
}
