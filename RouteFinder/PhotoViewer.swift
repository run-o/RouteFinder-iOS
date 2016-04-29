//
//  PhotoViewer.swift
//  RouteFinder
//
//  Created by Renaud Amar on 4/25/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit

class PhotoViewer: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    
    var photoFilePath: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (photoFilePath.isEmpty) {
            return
        }
        
        let image = UIImage(contentsOfFile:photoFilePath)
        photoView.image = image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
