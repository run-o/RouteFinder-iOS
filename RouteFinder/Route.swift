//
//  Route.swift
//  RouteFinder
//
//  Created by Renaud Amar on 5/1/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit

class Route {
    
    var name: String?  // name of the route
    var grade: String? // maybe should be an enum? might be easier as a string for international grades
    var areaID: Int32? // id of the area this route belongs to
    var timestamp: NSDate?
    
    // optionals:
    var rating: Int? // star rating of the route (should be enum)
    var firstAscent: String?
    var firstAscentYear: Int32?
    
}
