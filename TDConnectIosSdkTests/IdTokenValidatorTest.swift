//
//  IdTokenValidatorTest.swift
//  TDConnectIosSdk
//
//  Created by Jørund Fagerjord on 30/03/16.
//  Copyright © 2016 aerogear. All rights reserved.
//

import Foundation

import XCTest
import TDConnectIosSdk

class IdTokenValidatorTest: XCTestCase {
    
    func testMissingIssuerReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testUnmatchingIssuerReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuerAlmost", "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingAudienceReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testNotContainingAudienceReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": [], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testUntrustedAudiencePresentReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["untrustedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMoreThanOneAudienceButNoAuthorizedPartyReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience", "untrustedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMoreThanOneAudienceAndUnmatchingAuthorizedPartyReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience", "someAudience"], "azp": "someAudience", "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingExperationTimeReturnsError() {
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience"], "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testExpiredExperationTimeReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 - 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingIssueTimeReturnsError() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience"], "exp": experationTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testEverythingValidReturnsNils() {
        let experationTime: String = String(NSDate().timeIntervalSince1970 + 100)
        let issueTime: String = String(NSDate().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer", "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNil(error)
    }
}