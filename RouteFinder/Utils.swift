//
//  Utils.swift
//  RouteFinder
//
//  Created by Renaud Amar on 2/21/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import Foundation


class Utils
{
    static func degreesToRadians(x: Double) -> Double {
        return (M_PI * (x) / 180.0)
    }
    
    static func radiansToDegrees(x: Double) -> Double {
        return ((x) * 180.0 / M_PI)
    }
    
}