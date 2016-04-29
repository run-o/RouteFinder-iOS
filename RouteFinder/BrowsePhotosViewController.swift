//
//  BrowsePhotosViewController.swift
//  RouteFinder
//
//  Created by Renaud Amar on 2/28/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit

let reuseIdentifier = "PhotoCell"

class BrowsePhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let documentsURL : NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "viewPhotoSegue") {
            // TODO: open the thumbnail in the PhotoView
            let controller:PhotoViewer = segue.destinationViewController as! PhotoViewer;
            let indexPath: NSIndexPath = self.collectionView.indexPathForCell(sender as! UICollectionViewCell)!
            let photoFileName = NSUserDefaults.standardUserDefaults().stringForKey(String(format:"photoPath%d", indexPath.item+1))
            controller.photoFilePath = documentsURL.URLByAppendingPathComponent(photoFileName!).path!
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // UICollectionViewDataSource methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numPhotos = NSUserDefaults.standardUserDefaults().integerForKey("photoIndex")
        return numPhotos
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: PhotoThumbnail = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoThumbnail
        
        // load the photo for the current cell:
        let photoKey = String(format:"photoPath%d", indexPath.item+1)
        let photoFileName = NSUserDefaults.standardUserDefaults().stringForKey(photoKey)
        let photoFilePath = documentsURL.URLByAppendingPathComponent(photoFileName!).path
        let image = UIImage(contentsOfFile:photoFilePath!)
        cell.setThumbnailImage(image!)
        
        return cell
    }

}
