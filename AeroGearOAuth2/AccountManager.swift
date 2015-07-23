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

/**
A Config object that setups facebook specific configuration parameters.
*/
public class FacebookConfig: Config {
    /**
    Init a Facebook configuration.
    :param: clientId OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
    :param: clientSecret OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
    :param: scopes an array of scopes the app is asking access to.
    :param: accountId this unique id is used by AccountManager to identify the OAuth2 client.
    :paream: isOpenIDConnect to identify if fetching id information is required.
    */
    public init(clientId: String, clientSecret: String, scopes: [String], accountId: String? = nil, isOpenIDConnect: Bool = false) {
        super.init(base: "",
            authzEndpoint: "https://www.facebook.com/dialog/oauth",
            redirectURL: "fb\(clientId)://authorize/",
            accessTokenEndpoint: "https://graph.facebook.com/oauth/access_token",
            clientId: clientId,
            refreshTokenEndpoint: "https://graph.facebook.com/oauth/access_token",
            clientSecret: clientSecret,
            revokeTokenEndpoint: "https://www.facebook.com/me/permissions",
            isOpenIDConnect: isOpenIDConnect,
            userInfoEndpoint: isOpenIDConnect ? "https://graph.facebook.com/v2.2/me" : nil,
            scopes: scopes,
            accountId: accountId)
        // Add openIdConnect scope
        if self.isOpenIDConnect {
            if self.scopes[0].rangeOfString("public_profile") == nil {
                self.scopes[0] = self.scopes[0] + ", public_profile"
            }
        }
    }
}

/**
A Config object that setups Google specific configuration parameters.
*/
public class GoogleConfig: Config {
    /**
    Init a Google configuration.
    :param: clientId OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
    :param: scopes an array of scopes the app is asking access to.
    :param: accountId this unique id is used by AccountManager to identify the OAuth2 client.
    :paream: isOpenIDConnect to identify if fetching id information is required.
    */
    public init(clientId: String, scopes: [String], accountId: String? = nil, isOpenIDConnect: Bool = false) {
        let bundleString = NSBundle.mainBundle().bundleIdentifier ?? "google"
        super.init(base: "https://accounts.google.com",
            authzEndpoint: "o/oauth2/auth",
            redirectURL: "\(bundleString):/oauth2Callback",
            accessTokenEndpoint: "o/oauth2/token",
            clientId: clientId,
            refreshTokenEndpoint: "o/oauth2/token",
            revokeTokenEndpoint: "rest/revoke",
            isOpenIDConnect: isOpenIDConnect,
            userInfoEndpoint: isOpenIDConnect ? "https://www.googleapis.com/plus/v1/people/me/openIdConnect" : nil,
            scopes: scopes,
            accountId: accountId)
        // Add openIdConnect scope
        if self.isOpenIDConnect {
            self.scopes += ["openid", "email", "profile"]
        }
    }
}
/**
A Config object that setups Keycloak specific configuration parameters.
*/
public class KeycloakConfig: Config {
    /**
    Init a Keycloak configuration.
    :param: clientId OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
    :param: host to identify where is the keycloak server located.
    :param: realm to identify which realm to use. A realm grup a set of application/oauth2 client together.
    :paream: isOpenIDConnect to identify if fetching id information is required.
    */
    public init(clientId: String, host: String, realm: String? = nil, isOpenIDConnect: Bool = false) {
        let bundleString = NSBundle.mainBundle().bundleIdentifier ?? "keycloak"
        let defaulRealmName = String(format: "%@-realm", clientId)
        let realm = realm ?? defaulRealmName
        super.init(base: String(format: "%@/auth", host),
            authzEndpoint: String(format: "realms/%@/tokens/login", realm),
            redirectURL: "\(bundleString)://oauth2Callback",
            accessTokenEndpoint: String(format: "realms/%@/tokens/access/codes", realm),
            clientId: clientId,
            refreshTokenEndpoint: String(format: "realms/%@/tokens/refresh", realm),
            revokeTokenEndpoint: String(format: "realms/%@/tokens/logout", realm),
            isOpenIDConnect: isOpenIDConnect)
        // Add openIdConnect scope
        if self.isOpenIDConnect {
            self.scopes += ["openid", "email", "profile"]
        }
    }
}

/**
An account manager used to instantiate, store and retrieve OAuth2 modules.
*/
public class AccountManager {
    /// List of OAuth2 modules available for a given app. Each module is linked to an OAuht2Session which securely store the tokens.
    var modules: [String: OAuth2Module]
    
    init() {
        self.modules = [String: OAuth2Module]()
    }
    
    /// access a shared instance of an account manager
    public class var sharedInstance: AccountManager {
        struct Singleton {
            static let instance = AccountManager()
        }
        return Singleton.instance
    }
    
    /**
    Instantiate an OAuth2 Module using the configuration object passed in and adds it to the account manager. It uses the OAuth2Session account_id as the name that this module will be stored in.
    
    :param: config  the configuration object to use to setup an OAuth2 module.
    :param: moduleClass the type of the OAuth2 module to instantiate.
    
    :returns: the OAuth2 module
    */
    public class func addAccount(config: Config, moduleClass: OAuth2Module.Type) -> OAuth2Module {
        var myModule:OAuth2Module
        myModule = moduleClass.init(config: config)
        // TODO check accountId is unique in modules list
        sharedInstance.modules[myModule.oauth2Session.accountId] = myModule
        return myModule
    }
    
    /**
    Removes an OAuth2 module
    
    :param: name  the name that the OAuth2 module was bound to.
    :param: config the configuration object to use to setup an OAuth2 module.
    :param: moduleClass the type of the OAuth2 module to instantiate.
    
    :returns: the OAuth2module or nil if not found
    */
    public class func removeAccount(name: String, config: Config, moduleClass: OAuth2Module.Type) -> OAuth2Module? {
        return sharedInstance.modules.removeValueForKey(name)
    }
    
    /**
    Retrieves an OAuth2 module by a name
    
    :param: name the name that the OAuth2 module was bound to.
    
    :returns: the OAuth2module or nil if not found.
    */
    public class func getAccountByName(name: String) -> OAuth2Module? {
        return sharedInstance.modules[name]
    }
    
    /**
    Retrieves a list of OAuth2 modules bound to specific clientId.
    
    :param: clientId  the client it that the oauth2 module was bound to.
    
    :returns: the OAuth2module or nil if not found.
    */
    public class func getAccountsByClienId(clientId: String) -> [OAuth2Module] {
        let modules: [OAuth2Module] = [OAuth2Module](sharedInstance.modules.values)
        return modules.filter {$0.config.clientId == clientId }
    }

    
    /**
    Retrieves an OAuth2 module by using a configuration object.
    
    :param: config the Config object that this oauth2 module was used to instantiate.
    
    :returns: the OAuth2module or nil if not found.
    */
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

    /**
    Convenient method to retrieve a Facebook oauth2 module.
    
    :param: config a Facebook configuration object. See FacebookConfig.
    
    :returns: a Facebook OAuth2 module.
    */
    public class func addFacebookAccount(config: FacebookConfig) -> FacebookOAuth2Module {
        return addAccount(config, moduleClass: FacebookOAuth2Module.self) as! FacebookOAuth2Module
    }
    
    /**
    Convenient method to retrieve a Google oauth2 module ready to be used.
    
    :param: config a google configuration object. See GoogleConfig.
    
    :returns: a google OAuth2 module.
    */
    public class func addGoogleAccount(config: GoogleConfig) -> OAuth2Module {
        return addAccount(config, moduleClass: OAuth2Module.self)
    }
    
    /**
    Convenient method to retrieve a Keycloak oauth2 module ready to be used.
    
    :param: config a Keycloak configuration object. See KeycloakConfig.
    
    :returns: a Keycloak OAuth2 module.
    */
    public class func addKeycloakAccount(config: KeycloakConfig) -> KeycloakOAuth2Module {
        return addAccount(config, moduleClass: KeycloakOAuth2Module.self) as! KeycloakOAuth2Module
    }

}
