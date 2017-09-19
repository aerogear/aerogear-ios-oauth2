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
import Security

/**
The type of token to be saved in KeychainWrap:

- AccessToken: access token
- ExpirationDate: access token expiration date
- RefreshToken: refresh token
- RefreshExpirationDate: refresh token expiration date (used for Keycloak adapter only)
*/
public enum TokenType: String {
    case AccessToken = "AccessToken"
    case RefreshToken = "RefreshToken"
    case ExpirationDate = "ExpirationDate"
    case RefreshExpirationDate = "RefreshExpirationDate"
    case IdToken = "IdToken"
}

/**
A handy Keychain wrapper. It saves your OAuth2 tokens using WhenPasscodeSet ACL.
*/
public class KeychainWrap {

    /**
    The service id. By default set to apple bundle id.
    */
    public var serviceIdentifier: String

    /**
    The group id is Keychain access group which is used for sharing keychain content across multiple apps issued from same developer. By default there is no access group.
    */
    public var groupId: String?

    /**
    Initialize KeychainWrapper setting default values.

    :param: serviceId unique service, defaulted to bundleId
    :param: groupId used for SSO between app issued from same developer certificate.
    */
    public init(serviceId: String? =  Bundle.main.bundleIdentifier, groupId: String? = nil) {
        if serviceId == nil {
            self.serviceIdentifier = "unknown"
        } else {
            self.serviceIdentifier = serviceId!
        }
        self.groupId = groupId
    }

    /**
    Save tokens information in Keychain.

    :param: key usually use accountId for OAuth2 module, any unique string.
    :param: tokenType type of token: access, refresh.
    :param: value string value of the token.
    */
    public func save(key: String, tokenType: TokenType, value: String) -> Bool {
        let dataFromString: Data? = value.data(using: String.Encoding.utf8)
        if (dataFromString == nil) {
            return false
        }

        // Instantiate a new default keychain query
        let keychainQuery = NSMutableDictionary()
        if let groupId = self.groupId {
            keychainQuery[kSecAttrAccessGroup as String] = groupId
        }
        keychainQuery[kSecClass as String] = kSecClassGenericPassword
        keychainQuery[kSecAttrService as String] = self.serviceIdentifier
        keychainQuery[kSecAttrAccount as String] = key + "_" + tokenType.rawValue

        // Search for the keychain items
        let statusSearch: OSStatus = SecItemCopyMatching(keychainQuery, nil)

        // if found update
        if (statusSearch == errSecSuccess) {
            if (dataFromString != nil) {
                let attributesToUpdate = NSMutableDictionary()
                attributesToUpdate[kSecValueData as String] = dataFromString!

                let statusUpdate: OSStatus = SecItemUpdate(keychainQuery, attributesToUpdate)
                if (statusUpdate != errSecSuccess) {
                    print("tokens not updated")
                    return false
                }
            } else { // revoked token or newly installed app, clear KC
                return self.resetKeychain()
            }
        } else if(statusSearch == errSecItemNotFound) { // if new, add
            keychainQuery[kSecValueData as String] = dataFromString!
            let statusAdd: OSStatus = SecItemAdd(keychainQuery, nil)
            if(statusAdd != errSecSuccess) {
                print("tokens not saved (\(statusAdd))")
                return false
            }
        } else { // error case
            return false
        }

        return true
    }

    /**
    Delete a specific token in Keychain.

    :param: key usually use accountId for oauth2 module, any unique string.
    :param: tokenType type of token.
    */
    public func delete(key: String, tokenType: TokenType) -> Bool {
        let keychainQuery = NSMutableDictionary()
        if let groupId = self.groupId {
            keychainQuery[kSecAttrAccessGroup as String] = groupId
        }
        keychainQuery[kSecClass as String] = kSecClassGenericPassword
        keychainQuery[kSecAttrService as String] = self.serviceIdentifier
        keychainQuery[kSecAttrAccount as String] = key + "_" + tokenType.rawValue
        
        let statusDelete: OSStatus = SecItemDelete(keychainQuery)

        return statusDelete == noErr
    }

    /**
    Read tokens information in Keychain. If the entry is not found return nil.

    :param: userAccount key of the keychain entry, usually accountId for oauth2 module.
    :param: tokenType type of token: access, refresh.
    */
    public func read(userAccount: String, tokenType: TokenType) -> String? {
        let keychainQuery = NSMutableDictionary()
        if let groupId = self.groupId {
            keychainQuery[kSecAttrAccessGroup as String] = groupId
        }
        keychainQuery[kSecClass as String] = kSecClassGenericPassword
        keychainQuery[kSecAttrService as String] = self.serviceIdentifier
        keychainQuery[kSecAttrAccount as String] = userAccount + "_" + tokenType.rawValue
        keychainQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        keychainQuery[kSecReturnData as String] = kCFBooleanTrue
        
        var dataTypeRef: AnyObject?
        // Search for the keychain items
        let status: OSStatus = withUnsafeMutablePointer(to: &dataTypeRef) {
            SecItemCopyMatching(keychainQuery as CFDictionary, UnsafeMutablePointer($0))
        }

        if (status == errSecItemNotFound) {
            print("\(tokenType.rawValue) not found")
            return nil
        } else if (status != errSecSuccess) {
            print("Error attempting to retrieve \(tokenType.rawValue) with error code \(status) ")
            return nil
        }

        guard let keychainData = dataTypeRef as? Data else {
            return nil
        }

        return String(data: keychainData, encoding: String.Encoding.utf8)
    }

    /**
    Clear all keychain entries. Note that Keychain can only be cleared programmatically.
    */
    public func resetKeychain() -> Bool {
        return self.deleteAllKeysForSecClass(secClass: kSecClassGenericPassword) &&
            self.deleteAllKeysForSecClass(secClass: kSecClassInternetPassword) &&
            self.deleteAllKeysForSecClass(secClass: kSecClassCertificate) &&
            self.deleteAllKeysForSecClass(secClass: kSecClassKey) &&
            self.deleteAllKeysForSecClass(secClass: kSecClassIdentity)
    }

    func deleteAllKeysForSecClass(secClass: CFTypeRef) -> Bool {
        let keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClass as String] = secClass
        let result: OSStatus = SecItemDelete(keychainQuery)
        if (result == errSecSuccess) {
            return true
        } else {
            return false
        }
    }
}

/**
An OAuth2Session implementation to store OAuth2 metadata using the Keychain.
*/
public class TrustedPersistentOAuth2Session: OAuth2Session {

    /**
    The account id.
    */
    public var accountId: String

    /**
    The access token's expiration date.
    */
    public var accessTokenExpirationDate: Date? {
        
        get {
            
            if let timeIntervalAsString = self.keychain.read(userAccount: self.accountId, tokenType: .ExpirationDate),
               let unwrappedTimeInterval = TimeInterval(timeIntervalAsString) {
                
                return Date(timeIntervalSince1970: unwrappedTimeInterval)
                
            } else {
                
                return nil
            }
        }
        
        set(value) {
            
            if let unwrappedValue = value {
                
                let timeInterval = unwrappedValue.timeIntervalSince1970
                _ = self.keychain.save(key: self.accountId, tokenType: .ExpirationDate, value: String(timeInterval))
                
            } else {
                
                _ = self.keychain.delete(key: self.accountId, tokenType: .ExpirationDate)
            }
        }
    }

    /**
    The access token. The information is read securely from Keychain.
    */
    public var accessToken: String? {
        get {
            return self.keychain.read(userAccount: self.accountId, tokenType: .AccessToken)
        }
        set(value) {
            if let unwrappedValue = value {
                _ = self.keychain.save(key: self.accountId, tokenType: .AccessToken, value: unwrappedValue)
            } else {
                _ = self.keychain.delete(key: self.accountId, tokenType: .AccessToken)
            }
        }
    }

    /**
    The refresh token. The information is read securely from Keychain.
    */
    public var refreshToken: String? {
        get {
            return self.keychain.read(userAccount: self.accountId, tokenType: .RefreshToken)
        }
        set(value) {
            if let unwrappedValue = value {
                _ = self.keychain.save(key: self.accountId, tokenType: .RefreshToken, value: unwrappedValue)
            } else {
                _ = self.keychain.delete(key: self.accountId, tokenType: .RefreshToken)
            }
        }
    }

    /**
    The refresh token's expiration date.
    */
    public var refreshTokenExpirationDate: Date? {
        
        get {
            
            if let timeIntervalAsString = self.keychain.read(userAccount: self.accountId, tokenType: .ExpirationDate),
               let unwrappedTimeInterval = TimeInterval(timeIntervalAsString) {
                
                return Date(timeIntervalSince1970: unwrappedTimeInterval)
                
            } else {
                
                return nil
            }
        }
        
        set(value) {
            
            if let unwrappedValue = value {
                
                let timeInterval = unwrappedValue.timeIntervalSince1970
                _ = self.keychain.save(key: self.accountId, tokenType: .RefreshExpirationDate, value: String(timeInterval))
                
            } else {
                
                _ = self.keychain.delete(key: self.accountId, tokenType: .RefreshExpirationDate)
            }
        }
    }

    /**
    The JWT. The information is read securely from Keychain.
    */
    public var idToken: String? {
        get {
            return self.keychain.read(userAccount: self.accountId, tokenType: .IdToken)
        }
        set(value) {
            if let unwrappedValue = value {
                _ = self.keychain.save(key: self.accountId, tokenType: .IdToken, value: unwrappedValue)
            }
        }
    }

    private let keychain: KeychainWrap

    /**
    Check validity of accessToken. return true if still valid, false when expired.
    */
    public func tokenIsNotExpired() -> Bool {
        return  self.accessTokenExpirationDate != nil ? (self.accessTokenExpirationDate!.timeIntervalSince(Date()) > 0) : true
    }

    /**
    Check validity of refreshToken. return true if still valid, false when expired.
    */
    public func refreshTokenIsNotExpired() -> Bool {
        return  self.refreshTokenExpirationDate != nil ? (self.refreshTokenExpirationDate!.timeIntervalSince(Date()) > 0) : true
    }

    /**
    Save in memory tokens information. Saving tokens allow you to refresh accesstoken transparently for the user without prompting for grant access.
    */
    public func save(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?, idToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken

        let now = Date()
        if let inter = accessTokenExpiration?.doubleValue {
            self.accessTokenExpirationDate = now.addingTimeInterval(inter)
        }
        if let inter = refreshTokenExpiration?.doubleValue {
            self.refreshTokenExpirationDate = now.addingTimeInterval(inter)
        }
    }

    /**
    Clear all tokens. Method used when doing logout or revoke.
    */
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        self.accessTokenExpirationDate = nil
        self.refreshTokenExpirationDate = nil
        self.idToken = nil
    }

    /**
    Initialize TrustedPersistentOAuth2Session using account id. Account id is the service id used for keychain storage.

    :param: accountId uniqueId to identify the OAuth2Module
    :param: groupId used for SSO between app issued from same developer certificate.
    :param: accessToken optional parameter to initialize the storage with initial values
    :param: accessTokenExpirationDate optional parameter to initialize the storage with initial values
    :param: refreshToken optional parameter to initialize the storage with initial values
    :param: refreshTokenExpirationDate optional parameter to initialize the storage with initial values
    */
    public init(accountId: String,
        groupId: String? = nil,
        accessToken: String? = nil,
        accessTokenExpirationDate: Date? = nil,
        refreshToken: String? = nil,
        refreshTokenExpirationDate: Date? = nil) {
            self.accountId = accountId
            if groupId != nil {
                self.keychain = KeychainWrap(serviceId: groupId, groupId: groupId)
            } else {
                self.keychain = KeychainWrap()
            }

            if accessToken != nil {
                self.accessToken = accessToken
            }

            if refreshToken != nil {
                self.refreshToken = refreshToken
            }

            if accessToken != nil && accessTokenExpirationDate != nil {
                self.accessTokenExpirationDate = accessTokenExpirationDate as Date?
            }

            if refreshToken != nil && refreshTokenExpirationDate != nil {
                self.refreshTokenExpirationDate = refreshTokenExpirationDate
            }
    }
}
