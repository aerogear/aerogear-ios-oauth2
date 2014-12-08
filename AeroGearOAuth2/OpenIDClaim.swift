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

public class OpenIDClaim: Printable {
    public var sub: String?
    public var name: String?
    public var givenName: String?
    public var familyName: String?
    public var middleName: String?
    public var nickname: String?
    public var preferredUsername: String?
    public var profile: String?
    public var picture: String?
    public var website: String?
    public var email: String?
    public var emailVerified: Bool?
    public var gender: String?
    public var birthdate: String?
    public var zoneinfo: String?
    public var locale: String?
    public var phoneNumber: String?
    public var phoneNumberVerified: Bool?
    public var address: [String: AnyObject?]?
    public var updatedAt: Int?
    // google specific - not in spec?
    public var kind: String?
    public var hd: String?

    public var description: String {
        return  "sub: \(sub)\nname: \(name)\ngivenName: \(givenName)\nfamilyName: \(familyName)\nmiddleName: \(middleName)\n" +
            "nickname: \(nickname)\npreferredUsername: \(preferredUsername)\nprofile: \(profile)\npicture: \(picture)\n" +
        "website: \(website)\nemail: \(email)\nemailVerified: \(emailVerified)\ngender: \(gender)\nbirthdate: \(birthdate)\n"
    }
    
    public init(fromDict:[String: AnyObject]) {
        sub = fromDict["sub"] as? String
        name = fromDict["name"] as? String
        givenName = fromDict["given_name"] as? String
        familyName = fromDict["family_name"] as? String
        middleName = fromDict["middle_name"] as? String
        nickname = fromDict["nickname"] as? String
        preferredUsername = fromDict["preferred_username"] as? String
        profile = fromDict["profile"] as? String
        picture = fromDict["picture"] as? String
        website = fromDict["website"] as? String
        email = fromDict["email"] as? String
        emailVerified = fromDict["email_verified"] as? Bool
        gender = fromDict["gender"] as? String
        zoneinfo = fromDict["zoneinfo"] as? String
        locale = fromDict["locale"] as? String
        phoneNumber = fromDict["phone_number"] as? String
        phoneNumberVerified = fromDict["phone_number_verified"] as? Bool
        updatedAt = fromDict["updated_at"] as? Int
        kind = fromDict["sub"] as? String
        hd = fromDict["hd"] as? String
    }
}

public class FacebookOpenIDClaim: OpenIDClaim {
    
    override init(fromDict:[String: AnyObject]) {
        super.init(fromDict: fromDict)
        givenName = fromDict["first_name"] as? String
        familyName = fromDict["last_name"] as? String
        zoneinfo = fromDict["timezone"] as? String
    }
}


