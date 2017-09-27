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

/**
Handy extensions and utilities.
*/
extension String {
    
    public func urlEncode() -> String {
        let encodedURL = CFURLCreateStringByAddingPercentEscapes(nil,
            self as NSString,
            nil,
            "!@#$%&*'();:=+,/?[]" as CFString!,
            CFStringBuiltInEncodings.UTF8.rawValue)
        return encodedURL as! String
    }
}

public func merge(_ one: [String: String]?, _ two: [String:String]?) -> [String: String]? {
    var dict: [String: String]?
    if let one = one {
        dict = one
        if let two = two {
            for (key, value) in two {
                dict![key] = value
            }
        }
    } else {
        dict = two
    }
    return dict
}

