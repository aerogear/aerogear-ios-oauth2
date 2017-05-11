//
//  Session.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 7/31/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation

/// Provides the storage for session values
public protocol SessionStorage {
    
    /// The authenticated member.
    var member: Identifier?  { get set }
    
    /// Whether the device previously had a passcode.
    var hadPasscode: Bool { get set }
}

public extension SessionStorage {
    
    /// Resets the session storage.
    mutating func clear() {
        
        self.member = nil
    }
}

// MARK: - Implementations

public final class UserDefaultsSessionStorage: SessionStorage {
    
    public let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        
        self.userDefaults = userDefaults
    }
    
    public var member: Identifier? {
        
        get { return (userDefaults.object(forKey: Key.member.rawValue) as? NSNumber)?.int64Value }
        
        set {
            
            guard let member = newValue
                else { userDefaults.removeObject(forKey: Key.member.rawValue); return }
            
            userDefaults.set(NSNumber(value: member), forKey: Key.member.rawValue)
            
            userDefaults.synchronize()
        }
    }
    
    public var hadPasscode: Bool {
        
        get { return userDefaults.bool(forKey: Key.hadPasscode.rawValue) }
        
        set { userDefaults.set(newValue, forKey: Key.hadPasscode.rawValue) }
    }
    
    fileprivate enum Key: String {
        
        case member = "CoreSummit.UserDefaultsSessionStorage.Key.Member"
        case hadPasscode = "CoreSummit.UserDefaultsSessionStorage.Key.HadPasscode"
    }
}
