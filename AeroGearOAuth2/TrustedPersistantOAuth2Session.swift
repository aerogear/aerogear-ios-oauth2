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
// TODO AGIOS-256: Keychain wrapper implemented as part of AGIOS-103
// should be moved in aerogear-ios-crypto
import UIKit

//public enum ACL {
//    case WhenUnlockedAndPasswordSet
//    case WhenUnlocked
//    // TODO AGIOS-258 add acl for background processing
//}

public enum TokenType: String {
    case AccessToken = "AccessToken"
    case RefreshToken = "RefreshToken"
}

public class KeychainWrap {
    public var serviceIdentifier: String
    
    public init() {
        if let bundle = NSBundle.mainBundle().bundleIdentifier {
            self.serviceIdentifier = bundle
        } else {
            self.serviceIdentifier = "unkown"
        }
    }
    
    public func save(key: String, tokenType: TokenType, value: String) -> Bool {
        var dataFromString: NSData? = value.dataUsingEncoding(NSUTF8StringEncoding)
        if (dataFromString == nil) {
            return false
        }
        
        // Instantiate a new default keychain query
        var keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClass as String] = kSecClassGenericPassword
        keychainQuery[kSecAttrService as String] = self.serviceIdentifier
        keychainQuery[kSecAttrAccount as String] = key + "_" + tokenType.rawValue
        keychainQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        
        // TODO AGIOS-259 configure Swift version to get touchID access control
        // As of version beta7 kSecAccessControlUserPresence is not available in swift
        /*
        var error:  Unmanaged<CFError>?
        var sac: Unmanaged<SecAccessControl>?
        sac = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, &error)
        
        let opaque = sac?.toOpaque()
        if let op = opaque? {
            let retrievedData = Unmanaged<SecAccessControl>.fromOpaque(op).takeUnretainedValue()
            keychainQuery[kSecAttrAccessControl] = retrievedData
            keychainQuery[kSecUseNoAuthenticationUI] = false
        }
        */
        
        // Search for the keychain items
        let statusSearch: OSStatus = SecItemCopyMatching(keychainQuery, nil)
        
        // if found update
        if (statusSearch == errSecSuccess) {
            if (dataFromString != nil) {
                let attributesToUpdate = NSMutableDictionary()
                attributesToUpdate[kSecValueData as String] = dataFromString!
            
                var statusUpdate: OSStatus = SecItemUpdate(keychainQuery, attributesToUpdate)
                if (statusUpdate != errSecSuccess) {
                    println("tokens not updated")
                    return false
                }
            } else { // revoked token or newly installed app, clear KC
                return self.resetKeychain()
            }
        } else if(statusSearch == errSecItemNotFound) { // if new, add
            keychainQuery[kSecValueData as String] = dataFromString!
            var statusAdd: OSStatus = SecItemAdd(keychainQuery, nil)
            if(statusAdd != errSecSuccess) {
                 println("tokens not saved")
                return false
            }
        } else { // error case
            return false
        }
        
        return true
    }
    
    public func read(userAccount: String, tokenType: TokenType) -> NSString? {
        var keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClass as String] = kSecClassGenericPassword
        keychainQuery[kSecAttrService as String] = self.serviceIdentifier
        keychainQuery[kSecAttrAccount as String] = userAccount + "_" + tokenType.rawValue
        keychainQuery[kSecReturnData as String] = true
        keychainQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        
        var dataTypeRef: Unmanaged<AnyObject>?
        
        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        
        if (status == errSecItemNotFound) {
            println("\(tokenType.rawValue) not found")
            return nil
        } else if (status != errSecSuccess) {
            println("Error attempting to retrieve \(tokenType.rawValue) with error code \(status) ")
            return nil
        }
        
        let opaque = dataTypeRef?.toOpaque()
        
        var contentsOfKeychain: NSString?
        
        if let op = opaque? {
            let retrievedData = Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue()
            
            // Convert the data retrieved from the keychain into a string
            contentsOfKeychain = NSString(data: retrievedData, encoding: NSUTF8StringEncoding)
        } else {
            println("Nothing was retrieved from the keychain. Status code \(status)")
        }
        
        return contentsOfKeychain
    }
    
    // when uninstalling app you may wish to clear keyclain app info
    public func resetKeychain() -> Bool {
        return self.deleteAllKeysForSecClass(kSecClassGenericPassword) &&
        self.deleteAllKeysForSecClass(kSecClassInternetPassword) &&
        self.deleteAllKeysForSecClass(kSecClassCertificate) &&
        self.deleteAllKeysForSecClass(kSecClassKey) &&
        self.deleteAllKeysForSecClass(kSecClassIdentity)
    }
    
    func deleteAllKeysForSecClass(secClass: CFTypeRef) -> Bool {
        var keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClass as String] = secClass

        let result:OSStatus = SecItemDelete(keychainQuery)
        if (result == errSecSuccess) {
            return true
        } else {
            return false
        }
    }
}


// TODO When passcode is set in iPhone settings => ok
// if passcode is not set (not secure phone) session will fail to save tokens 
// in keychain, implement a customizable fallback mechanism. Maybe in form of 
// closure taken as init param. 
// When passcode is not set to securely safe password we need to encrypt
// so we need user to be prompted to enter a password
public class TrustedPersistantOAuth2Session: OAuth2Session {
    
    /**
    * The account id.
    */
    public var accountId: String
    
    /**
    * The access token's expiration date.
    */
    public var accessTokenExpirationDate: NSDate?
    
    public var accessToken: String? {
        get {
            return self.keychain.read(self.accountId, tokenType: .AccessToken)
        }
        set(value) {
            if let unwrappedValue = value {
                let result = self.keychain.save(self.accountId, tokenType: .AccessToken, value: unwrappedValue)
            }
        }
    }
    
    public var refreshToken: String? {
        get {
            return self.keychain.read(self.accountId, tokenType: .RefreshToken)
        }
        set(value) {
            if let unwrappedValue = value {
                self.keychain.save(self.accountId, tokenType: .RefreshToken, value: unwrappedValue)
            }
        }
    }
    
    private let keychain: KeychainWrap
    
    /**
    * Check validity of accessToken. return true if still valid, false when expired.
    */
    public func tokenIsNotExpired() -> Bool {
        return self.accessTokenExpirationDate?.timeIntervalSinceDate(NSDate()) > 0 ;
    }
    
    /**
    * Save in memory tokens information. Saving tokens allow you to refresh accesstoken transparently for the user without prompting
    * for grant access.
    */
    public func saveAccessToken(accessToken: String?, refreshToken: String?, expiration: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        let now = NSDate()
        if let inter = expiration?.doubleValue {
            self.accessTokenExpirationDate = now.dateByAddingTimeInterval(inter)
        }
    }
    public func saveAccessToken() {
        self.accessToken = nil
        self.refreshToken = nil
        self.accessTokenExpirationDate = nil
    }
    
    public init(accountId: String, accessToken: String? = nil, accessTokenExpirationDate: NSDate? = nil, refreshToken: String? = nil) {
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.accountId = accountId
        self.keychain = KeychainWrap()
        // TODO Shoot config to reset all keychain + choose ACL type: with or without touchID
        // for now to clear keychain contain for your app uncomment line below
        //self.keychain.resetKeychain()
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
