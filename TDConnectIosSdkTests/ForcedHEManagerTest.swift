//
//  ForcedHEManagerTest.swift
//  TDConnectIosSdkTests
//

import Foundation
import XCTest
import TDConnectIosSdk
import AeroGearHttp
import OHHTTPStubs

func setupForcedStubWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    _ = stub({_ in return true}, response: { (request: URLRequest!) -> OHHTTPStubsResponse in
        //_ = ["name": "John", "family_name": "Smith"]
        switch request.url!.path {
        case "/oauth/.well-known/openid-configuration":
            let string = "{\"grant_types_supported\": [\"refresh_token\",\"authorization_code\"],\"id_token_signing_alg_values_supported\": [\"RS256\",\"none\"]}"
            let data = string.data(using: String.Encoding.utf8)
            return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
        case "/oauth/.well-known/openid-configuration-bad-url":
            let string = ""
            let data = string.data(using: String.Encoding.utf8)
            return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
        default:
            return OHHTTPStubsResponse(error: NSError(domain: "TimeoutErrorDomain", code: URLError.timedOut.rawValue, userInfo: nil))
        }
    })
}

class ForcedHEManagerTestModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupForcedStubWithNSURLSessionDefaultConfiguration()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testGetRemoteConfiguration() {
        let expectation = self.expectation(description: "GetRemoteConfiguration")
        let baseUrl = "https://connect.staging.telenordigital.com/oauth"
        let url = String(format: "%@", "\(baseUrl)/.well-known/openid-configuration")

        ForcedHEManager.fetchWellknown(url) { (success) in
            XCTAssert(success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetRemoteConfigurationBadUrl() {
        let expectation = self.expectation(description: "GetRemoteConfigurationBadUrl")
        let baseUrl = "https://connect.staging.telenordigital.com/oauth"
        let url = String(format: "%@", "\(baseUrl)/.well-known/openid-configuration-bad-url")

        ForcedHEManager.fetchWellknown(url) { (success) in
            XCTAssert(!success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetRemoteConfigurationTimeout() {
        let expectation = self.expectation(description: "GetRemoteConfigurationTimeout")
        let baseUrl = "https://connect.staging.telenordigital.com/oauth"
        let url = String(format: "%@", "\(baseUrl)")

        ForcedHEManager.fetchWellknown(url) { (success) in
            XCTAssert(!success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

}

