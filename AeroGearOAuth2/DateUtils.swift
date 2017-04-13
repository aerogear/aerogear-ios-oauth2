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
Handy extensions to NSDate
*/
extension Date {

    /**
    Initialize a date object using the given string.

    :param: dateString the string that will be used to instantiate the date object. The string is expected to be in the format 'yyyy-MM-dd hh:mm:ss a'.

    :returns: the NSDate object.
    */
    public init(dateString: String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        let d = dateStringFormatter.date(from: dateString)
        if let unwrappedDate = d {
            self.init(timeInterval:0, since:unwrappedDate)
        } else {
            self.init()
        }
    }


    /**
    Returns a string of the date object using the format 'yyyy-MM-dd hh:mm:ss a'.

    :returns: a formatted string object.
    */
    public func toString() -> String {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        return dateStringFormatter.string(from: self)
    }
}
