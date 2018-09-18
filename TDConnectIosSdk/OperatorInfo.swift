//
//  OperatorInfo.swift
//  Pods
//
//  Created by Atanas Bakalov on 30/05/2017.
//
//

import Foundation
import CoreTelephony

class OperatorInfo {
    class func id() -> String {
        #if targetEnvironment(simulator)
            return "24201"
        #else
            let networkInfo =  CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            let mcc = carrier!.mobileCountryCode
            let mnc = carrier!.mobileNetworkCode

            return NSString(format: "%@%@", mcc!, mnc!) as String
        #endif
    }
}
