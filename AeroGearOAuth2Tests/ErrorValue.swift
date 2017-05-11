//
//  ErrorValue.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 6/6/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

/// Basic wrapper for error / value pairs.
public enum ErrorValue<T> {
    
    case error(Error)
    case value(T)
}
