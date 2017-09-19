//
//  StoreTests.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 6/16/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import XCTest
import Foundation
import CoreData

final class StoreTests: XCTestCase {
    
    func testAllSummitsRequest() {
        
        let store = try! createStore()
        
        let expectation = self.expectation(description: "API Request")
        
        store.summits() { (response) in
            
            switch response {
                
            case let .error(error):
                
                XCTFail("\(error)");
                
            case let .value(value):
                
                XCTAssert(value.items.isEmpty == false, "No summits")
                
                dump(value)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 60, handler: nil)
    }
}

func createStore() throws -> Store {
    
    return try Store(environment: .staging,
                     session: UserDefaultsSessionStorage(),
                     createPersistentStore: {
                        try $0.addPersistentStore(ofType: NSInMemoryStoreType,
                                                  configurationName: nil,
                                                  at: nil,
                                                  options: nil) },
                     deletePersistentStore: { _ in fatalError("Not needed") })
}
