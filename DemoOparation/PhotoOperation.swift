//
//  PhotoOperation.swift
//  DemoOparation
//
//  Created by Dat Liforte on 3/27/17.
//  Copyright © 2017 Liforte. All rights reserved.
//

import Foundation
import UIKit

enum PhotoRecordState {
    case New, Downloader, Filtered, Failed
}

class PhotoRecord{
    let name: String
    let url: URL
    var state = PhotoRecordState.New
    var image = UIImage(named: "ic_thumb")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

class PendingOperation {
    lazy var dlProgress = [NSIndexPath : Operation]()
    lazy var dlQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "operation queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var filtrationsInProgress = [NSIndexPath : Operation]()
    lazy var filtrationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "operation queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

class ImageDownloader: Operation {
    
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.isCancelled {
            return
        }
        
        let data = NSData(contentsOf: self.photoRecord.url)
        
        if self.isCancelled {
            return
        }
        
        if (data?.length)! > 0 {
            self.photoRecord.image = UIImage(data: data as! Data)
            self.photoRecord.state = .Downloader
        }else{
            self.photoRecord.image = UIImage(named: "failer")
            self.photoRecord.state = .Failed
        }
    }
}

class ImageFiltration: Operation {
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main () {
        if self.isCancelled {
            return
        }
        
        if self.photoRecord.state != .Downloader {
            return
        }
        
        if let filteredImage = self.applySepiaFilter(image: self.photoRecord.image!) {
            self.photoRecord.image = filteredImage
            self.photoRecord.state = .Filtered
        }
    }
    
    func applySepiaFilter(image:UIImage) -> UIImage? {
        let inputImage = CIImage(data:UIImagePNGRepresentation(image)!)
        
        if self.isCancelled {
            return nil
        }
        let context = CIContext(options:nil)
        let filter = CIFilter(name:"CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(0.8, forKey: "inputIntensity")
        let outputImage = filter?.outputImage
        
        if self.isCancelled {
            return nil
        }
        
        let outImage = context.createCGImage(outputImage!, from: outputImage!.extent)
        let returnImage = UIImage(cgImage: outImage!)
        return returnImage
    }
}
