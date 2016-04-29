//
//  PhotoThumbnail.swift
//  RouteFinder
//
//  Created by Renaud Amar on 4/26/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit

class PhotoThumbnail: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setThumbnailImage(thumbnailImage: UIImage) {
        self.imageView.image = thumbnailImage
    }
}
