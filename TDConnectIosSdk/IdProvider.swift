//
//  IdProvider.swift
//  TDConnectIosSdk
//
//  Created by Serhii Bovtriuk on 29/04/2019.
//  Copyright © 2019 aerogear. All rights reserved.
//

import Foundation

public enum IdProvider {
    case connectId, telenorId
    func getUrl(useStaging: Bool) -> String {
        switch self {
            case .connectId:
                return useStaging ? "https://connect.staging.telenordigital.com/oauth" : "https://connect.telenordigital.com/oauth";
            case .telenorId:
                return useStaging ? "https://staging.telenorid.com/oauth" : "example.com"; // TODO: Production is not set yet
        }
    }
}
