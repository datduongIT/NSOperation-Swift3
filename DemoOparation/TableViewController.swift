//
//  TableViewController.swift
//  DemoOparation
//
//  Created by Dat Liforte on 3/27/17.
//  Copyright © 2017 Liforte. All rights reserved.
//

import UIKit

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var tbvPhoto: UITableView!
    
    var photos = [PhotoRecord]()
    let pendingOperation = PendingOperation()

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPhotoDetail()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func fetchPhotoDetail() {
        
        let request = NSURLRequest(url: dataSourceURL!)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data, response, error in
            
            if data != nil{
                let datasourceDictionary = try! PropertyListSerialization.propertyList(from: data!, options: [], format: nil) as! NSDictionary
                for(key, value) in datasourceDictionary {
                    let name = key as? String
                    let url = URL(string: (value as? String)!)
                    
                    if name != nil && url != nil {
                        let photoRecord = PhotoRecord(name: name!, url: url!)
                        self.photos.append(photoRecord)
                    }
                    
                }
                self.tbvPhoto.reloadData()
            }
            if error != nil {
                let alert = UIAlertController(title: "Ops!", message: "error", preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                alert.show(self, sender: self)
            }
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
        }
        task.resume()
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return photos.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath) as! TableViewCell
        
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            cell.accessoryView = indicator
        }
        
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let photoDetail = photos[indexPath.row]
        
        //3
        cell.name?.text = photoDetail.name
        cell.imvImage.image = photoDetail.image
        
        switch photoDetail.state {
        case .Filtered:
            indicator.stopAnimating()
        case .Failed:
            indicator.stopAnimating()
        case .New, .Downloader:
            indicator.startAnimating()
            if !tbvPhoto.isDragging && !tbvPhoto.isDecelerating {
                startOperationsForPhotoRecord(photoDetail: photoDetail, indexPath: indexPath as NSIndexPath)
            }
        }

        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
    func suspendAllOperations () {
        pendingOperation.dlQueue.isSuspended = true
        pendingOperation.filtrationQueue.isSuspended = true
    }
    
    func resumeAllOperations () {
        pendingOperation.dlQueue.isSuspended = false
        pendingOperation.filtrationQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells() {
        //1
        if let pathsArray = tbvPhoto.indexPathsForVisibleRows {
            //2
            var allPendingOperations = Set(Array(pendingOperation.dlProgress.keys))
            allPendingOperations.formUnion(Array(pendingOperation.filtrationsInProgress.keys))
            
            //3
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray)
            toBeCancelled.subtract(visiblePaths as Set<NSIndexPath>)
            
            //4
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations as Set<IndexPath>)
            
            // 5
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperation.dlProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperation.dlProgress.removeValue(forKey: indexPath)
                if let pendingFiltration = pendingOperation.filtrationsInProgress[indexPath] {
                    pendingFiltration.cancel()
                }
                pendingOperation.filtrationsInProgress.removeValue(forKey: indexPath)
            }
            
            // 6
            for indexPath in toBeStarted {
                let indexPath = indexPath as NSIndexPath
                let recordToProcess = self.photos[indexPath.row]
                startOperationsForPhotoRecord(photoDetail: recordToProcess, indexPath: indexPath)
            }
        }
    }
    
    func startOperationsForPhotoRecord(photoDetail: PhotoRecord, indexPath: NSIndexPath){
        switch photoDetail.state {
        case .Downloader:
            startFiltrationForRecord(photoDetail: photoDetail, indexPath: indexPath)
        case .New:
            startDownloadForRecord(photoDetail: photoDetail, indexPath: indexPath)
        default:
            NSLog("Do nothing")
        }
    }
    
    func startDownloadForRecord(photoDetail: PhotoRecord, indexPath: NSIndexPath){
        if pendingOperation.dlProgress[indexPath] != nil {
            return
        }
        
        let imageDL = ImageDownloader(photoRecord: photoDetail)
        
        imageDL.completionBlock = {
            if imageDL.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperation.dlProgress.removeValue(forKey: indexPath)
                self.tbvPhoto.reloadRows(at: [indexPath as IndexPath], with: .fade)
            }
        }
        
        pendingOperation.dlProgress[indexPath] = imageDL
        pendingOperation.dlQueue.addOperation(imageDL)
    }
    
    func startFiltrationForRecord(photoDetail: PhotoRecord, indexPath: NSIndexPath){
        if pendingOperation.filtrationsInProgress[indexPath] != nil{
            return
        }
        
        let filterer = ImageFiltration(photoRecord: photoDetail)
        
        filterer.completionBlock = {
            if filterer.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperation.filtrationsInProgress.removeValue(forKey: indexPath)
                self.tbvPhoto.reloadRows(at: [indexPath as IndexPath], with: .fade)
            }
            
        }
        
        pendingOperation.filtrationsInProgress[indexPath] = filterer
        pendingOperation.filtrationQueue.addOperation(filterer)
        
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
