//
//  OrientationFinderView.swift
//  RouteFinder
//
//  Created by Renaud Amar on 8/23/15.
//  Copyright (c) 2015 Renaud Amar. All rights reserved.
//

import Foundation
import UIKit

class OrientationFinderView: UIView {
    
    var azimuthOffset : CGFloat = 0.0
    var inclinationOffset : CGFloat = 0.0
    
    override func drawRect(rect: CGRect) {
        //var smallRect : CGRect = rect.rectByInsetting(dx: <#CGFloat#>, dy: <#CGFloat#>)
        
        var path = UIBezierPath(ovalInRect: CGRectInset(rect, 5, 5))
        UIColor.blueColor().setStroke()
        path.lineWidth = 5
        path.stroke()
       
        var currentRect: CGRect = rect.insetBy(dx: 45, dy: 45)
        azimuthOffset = azimuthOffset % 180
        currentRect.offsetInPlace(dx: azimuthOffset*50/180, dy: inclinationOffset*50/90)
        path = UIBezierPath(ovalInRect: currentRect)
        UIColor.redColor().setFill()
        path.fill()
    }

}