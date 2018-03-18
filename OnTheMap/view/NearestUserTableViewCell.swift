//
//  NearestUserTableViewCell.swift
//  OnTheMap
//
//  Created by Swifta on 3/11/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class NearestUserTableViewCell: UITableViewCell {

    @IBOutlet weak var pin: UIImageView!
    @IBOutlet weak var userName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
