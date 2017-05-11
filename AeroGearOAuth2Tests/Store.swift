//
//  Store.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 6/14/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation
import CoreData
import AeroGearHttp
import AeroGearOAuth2

/// Class used for requesting and caching data from the server.
public final class Store {
    
    // MARK: - Properties
    
    /// The managed object context used for caching.
    public let managedObjectContext: NSManagedObjectContext
    
    /// A convenience variable for the managed object model.
    public let managedObjectModel: NSManagedObjectModel
    
    /// Block for creating the persistent store.
    public let createPersistentStore: (NSPersistentStoreCoordinator) throws -> NSPersistentStore
    
    /// Block for resetting the persistent store.
    public let deletePersistentStore: (NSPersistentStoreCoordinator, NSPersistentStore) throws -> ()
    
    /// The server targeted environment. 
    public let environment: Environment
    
    /// Provides the storage for session values. 
    public var session: SessionStorage
    
    // MARK: - Private / Internal Properties
    
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    private var persistentStore: NSPersistentStore
    
    /// The managed object context running on a background thread for asyncronous caching.
    public let privateQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
    
    /// Request queue
    internal let requestQueue: OperationQueue = {
        
        let queue = OperationQueue()
        
        queue.name = "\(Store.self) Request Queue"
        
        return queue
    }()
    
    internal var oauthModuleOpenID: OAuth2Module!
    
    internal var oauthModuleServiceAccount: OAuth2Module!
    
    // MARK: - Initialization
    
    deinit {
    
        // stop recieving 'didSave' notifications from private context
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.privateQueueManagedObjectContext)
    
        NotificationCenter.default.removeObserver(self)
    }
    
    public init(environment: Environment,
                 session: SessionStorage,
                 contextConcurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType,
                 createPersistentStore: @escaping (NSPersistentStoreCoordinator) throws -> NSPersistentStore,
                 deletePersistentStore: @escaping (NSPersistentStoreCoordinator, NSPersistentStore) throws -> ()) throws {
        
        // store values
        self.environment = environment
        self.session = session
        self.createPersistentStore = createPersistentStore
        self.deletePersistentStore = deletePersistentStore
        
        // set managed object model
        self.managedObjectModel = NSManagedObjectModel()
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        // setup managed object contexts
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: contextConcurrencyType)
        self.managedObjectContext.undoManager = nil
        self.managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.privateQueueManagedObjectContext.undoManager = nil
        self.privateQueueManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        self.privateQueueManagedObjectContext.name = "\(Store.self) Private Managed Object Context"
        
        // configure CoreData backing store
        self.persistentStore = try createPersistentStore(persistentStoreCoordinator)
        
        // listen for notifications (for merging changes)
        NotificationCenter.default.addObserver(self, selector: #selector(Store.mergeChangesFromContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.privateQueueManagedObjectContext)
        
        
        // config OAuth and HTTP
        configOAuthAccounts()
        
        /* Removed from lib
        NotificationCenter.default.removeObserver(self, name: OAuth2Module.revokeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(revokedAccess),
            name: OAuth2Module.revokeNotification,
            object: nil)
        */
    }
    
    // MARK: - Accessors
    
    public var deviceHasPasscode: Bool {
        
        let secret = "Device has passcode set?".data(using: String.Encoding.utf8, allowLossyConversion: false)
        let attributes = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "LocalDeviceServices", kSecAttrAccount as String:"NoAccount", kSecValueData as String: secret!, kSecAttrAccessible as String:kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly] as [String : Any]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == 0 {
            SecItemDelete(attributes as CFDictionary)
            return true
        }
        return false
    }
    
    // MARK: - Methods
    
    public func clear() throws {
        
        try self.deletePersistentStore(persistentStoreCoordinator, persistentStore)
        self.persistentStore = try self.createPersistentStore(persistentStoreCoordinator)
        
        self.managedObjectContext.reset()
        self.privateQueueManagedObjectContext.reset()
        
        // manually send notification
        NotificationCenter.default.post(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext, userInfo: [:])
        
        #if os(iOS)
        // logout
        //self.logout()
        #endif
    }
    
    // MARK: - Internal / Private Methods
    
    /// Convenience function for adding a block to the request queue.
    @inline(__always)
    internal func newRequest(_ block: @escaping () -> ()) {
        
        self.requestQueue.addOperation(block)
    }
    
    // MARK: - OAuth2
    
    internal func createHTTP(_ type: RequestType) -> Http {
        
        let http: Http
        if (type == .openIDGetFormUrlEncoded) {
            http = Http(responseSerializer: StringResponseSerializer())
            http.authzModule = oauthModuleOpenID
        }
        else if (type == .openIDJSON) {
            http = Http(requestSerializer: JsonRequestSerializer(), responseSerializer: StringResponseSerializer())
            http.authzModule = oauthModuleOpenID
        }
        else {
            http = Http(responseSerializer: StringResponseSerializer())
            http.authzModule = oauthModuleServiceAccount
        }
        return http
    }
    
    fileprivate func configOAuthAccounts() {
        
        let hasPasscode = deviceHasPasscode
        
        var openIDScopes = ["openid",
                      "offline_access",
                      "\(environment.configuration.serverURL)/me/read",
                      "\(environment.configuration.serverURL)/summits/read",
                      "\(environment.configuration.serverURL)/summits/write",
                      "\(environment.configuration.serverURL)/summits/read-external-orders",
                      "\(environment.configuration.serverURL)/summits/confirm-external-orders",
                      "\(environment.configuration.serverURL)/me/summits/events/favorites/add",
                      "\(environment.configuration.serverURL)/me/summits/events/favorites/delete"]
        
        var serviceAccountScopes = ["\(environment.configuration.serverURL)/summits/read"]
        
        if environment == .staging {
            
            // openID staging scopes
            
            openIDScopes += ["\(environment.configuration.serverURL)/teams/read",
                              "\(environment.configuration.serverURL)/teams/write",
                              "\(environment.configuration.serverURL)/members/invitations/read",
                              "\(environment.configuration.serverURL)/members/invitations/write"]
            
            // service account staging scopes
            serviceAccountScopes += ["\(environment.configuration.serverURL)/members/read"]
        }
        
        var config = Config(
            base: environment.configuration.authenticationURL,
            authzEndpoint: "oauth2/auth",
            redirectURL: "org.openstack.ios.openstack-summit://oauthCallback",
            accessTokenEndpoint: "oauth2/token",
            clientId: environment.configuration.openID.client,
            refreshTokenEndpoint: "oauth2/token",
            revokeTokenEndpoint: "oauth2/token/revoke",
            isOpenIDConnect: true,
            userInfoEndpoint: "api/v1/users/info",
            scopes: openIDScopes,
            clientSecret: environment.configuration.openID.secret,
            isWebView: true
        )
        oauthModuleOpenID = createOAuthModule(config, hasPasscode: hasPasscode)
        
        config = Config(
            base: environment.configuration.authenticationURL,
            authzEndpoint: "oauth2/auth",
            redirectURL: "org.openstack.ios.openstack-summit://oauthCallback",
            accessTokenEndpoint: "oauth2/token",
            clientId: environment.configuration.serviceAccount.client,
            revokeTokenEndpoint: "oauth2/token/revoke",
            isServiceAccount: true,
            userInfoEndpoint: "api/v1/users/info",
            scopes: serviceAccountScopes,
            clientSecret: environment.configuration.serviceAccount.secret
        )
        oauthModuleServiceAccount = createOAuthModule(config, hasPasscode: hasPasscode)
    }
    
    fileprivate func createOAuthModule(_ config: AeroGearOAuth2.Config, hasPasscode: Bool) -> OAuth2Module {
        var session: OAuth2Session
        
        config.accountId = "ACCOUNT_FOR_CLIENTID_\(config.clientId)"
        
        if self.session.hadPasscode && !hasPasscode {
            
            session = TrustedPersistentOAuth2Session(accountId: config.accountId!)
            session.clearTokens()
        }
        
        session = hasPasscode ? TrustedPersistentOAuth2Session(accountId: config.accountId!) : UntrustedMemoryOAuth2Session(accountId: config.accountId!)
        
        return AccountManager.addAccountWith(config: config, moduleClass: OpenStackOAuth2Module.self, session: session)
    }
    
    // MARK: Notifications
    
    @objc fileprivate func mergeChangesFromContextDidSaveNotification(_ notification: Foundation.Notification) {
        
        self.managedObjectContext.performAndWait {
            
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
            
            // manually send notification
            NotificationCenter.default.post(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext, userInfo: notification.userInfo)
        }
    }
    
    @objc fileprivate func revokedAccess(_ notification: Foundation.Notification) {
        
        self.session.clear()
        
        let notification = Foundation.Notification(name: Store.Notification.forcedLoggedOut, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
    }
}

// MARK: - Supporting Types

/// Convenience function for adding a block to the main queue.
internal func mainQueue(_ block: @escaping () -> ()) {
    
    OperationQueue.main.addOperation(block)
}

public extension Store {
    
    public enum Error: Swift.Error {
        
        /// The server returned a status code indicating an error.
        case errorStatusCode(Int)
        
        /// The server returned an invalid response.
        case invalidResponse
        
        /// A custom error from the server.
        case customServerError(String)
    }
}

public extension Store {
    
    public struct Notification {
        
        public static let loggedIn = Foundation.Notification.Name(rawValue: "CoreSummit.Store.Notification.LoggedIn")
        public static let loggedOut = Foundation.Notification.Name(rawValue: "CoreSummit.Store.Notification.LoggedOut")
        public static let forcedLoggedOut = Foundation.Notification.Name(rawValue: "CoreSummit.Store.Notification.ForcedLoggedOut")
    }
}

internal extension Store {
    
    enum RequestType {
        
        case openIDGetFormUrlEncoded, openIDJSON, serviceAccount
    }
}
