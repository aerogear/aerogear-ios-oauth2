//
//  IdTokenValidator.swift
//  Pods
//
//  Created by Jørund Fagerjord on 16/03/16.
//
//

import Foundation

public enum IdTokenValidationError: Error {
    case IncorrectIssuer(String)
    case MissingIssuer
    case MissingAudience(String)
    case UntrustedAudiences(String)
    case AuthorizedPartyMissing(String)
    case AuthorizedPartyMismatch(String)
    case ExperationTimeMissing
    case Expired(String)
    case MissingIssueTime(String)
}

public func validateIdToken(token: [String:AnyObject], expectedIssuer: String, expectedAudience: String) -> IdTokenValidationError? {
    
    guard let issuer = token["iss"] as? String else {
        return IdTokenValidationError.MissingIssuer
    }
    
    if issuer != expectedIssuer {
        return IdTokenValidationError.IncorrectIssuer("Found issuer was: \(issuer)")
    }
    
    guard let audience = token["aud"] as? [String] else {
        return IdTokenValidationError.MissingAudience("ID token audience was nil.")
    }
    
    if !audience.contains(expectedAudience) {
        return IdTokenValidationError.MissingAudience("ID token audience list does not contain the configured client ID.")
    }
    
    let untrustedAudiences = audience.filter({ (s: String) -> Bool in
        s != expectedAudience
    })
    if untrustedAudiences.count != 0 {
        return IdTokenValidationError.UntrustedAudiences("ID token audience list contains untrusted audiences.")
    }
    
    let authorizedParty: String? = token["azp"] as? String
    if audience.count > 1 && authorizedParty == nil {
        return IdTokenValidationError.AuthorizedPartyMissing("ID token contains multiple audiences but no azp claim is present.")
    }
    
    if audience.count > 1 && authorizedParty != expectedAudience {
        return IdTokenValidationError.AuthorizedPartyMismatch("ID token authorized party is not the configured client ID.")
    }
    
    guard let experationTime = token["exp"] as? TimeInterval ?? token["exp"]?.doubleValue as TimeInterval? else {
        return IdTokenValidationError.ExperationTimeMissing
    }
    
    let experationDate = NSDate(timeIntervalSince1970: experationTime)
    if experationDate.timeIntervalSinceNow.sign == FloatingPointSign.minus {
        return IdTokenValidationError.Expired("ID token has expired.")
    }
    
    guard let _ = token["iat"] else {
        return IdTokenValidationError.MissingIssueTime("ID token is missing the \"iat\" claim.")
    }
    
    return nil
}
