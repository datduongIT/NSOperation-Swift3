//
//  TableViewCell.swift
//  DemoOparation
//
//  Created by Dat Liforte on 3/27/17.
//  Copyright © 2017 Liforte. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var imvImage: UIImageView!    
    @IBOutlet weak var name: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
