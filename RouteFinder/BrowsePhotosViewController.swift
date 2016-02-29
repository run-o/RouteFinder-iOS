//
//  BrowsePhotosViewController.swift
//  RouteFinder
//
//  Created by Renaud Amar on 2/28/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit

class BrowsePhotosViewController: UIViewController {

    @IBOutlet weak var photoView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let imageFileName = NSUserDefaults.standardUserDefaults().stringForKey("imagePath"
        var image = UIImage(contentsOfFile:imageFileName!)
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
