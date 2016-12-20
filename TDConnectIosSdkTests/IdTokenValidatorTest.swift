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
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testUnmatchingIssuerReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuerAlmost" as AnyObject, "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingAudienceReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "exp": experationTime as AnyObject, "iat": issueTime as AnyObject]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testNotContainingAudienceReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": [], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testUntrustedAudiencePresentReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["untrustedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMoreThanOneAudienceButNoAuthorizedPartyReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience", "untrustedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMoreThanOneAudienceAndUnmatchingAuthorizedPartyReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience", "someAudience"], "azp": "someAudience", "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingExperationTimeReturnsError() {
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience"], "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testExpiredExperationTimeReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 - 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testMissingIssueTimeReturnsError() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience"], "exp": experationTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNotNil(error)
    }
    
    func testEverythingValidReturnsNils() {
        let experationTime: String = String(Date().timeIntervalSince1970 + 100)
        let issueTime: String = String(Date().timeIntervalSince1970)
        let token: [String: AnyObject] = ["iss": "expectedIssuer" as AnyObject, "aud": ["expectedAudience"], "exp": experationTime, "iat": issueTime]
        let error: IdTokenValidationError? = validateIdToken(token, expectedIssuer: "expectedIssuer", expectedAudience: "expectedAudience")
        XCTAssertNil(error)
    }
}
