//
//  Users.swift
//  OnTheMap
//
//  Created by Swifta on 3/11/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct Users {
    var firstName: String = ""
    var lastName: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var mapString: String = ""
    var mediaURL: String = ""
    var objectId: String = ""
    var uniqueKey: String = ""
    var dict: [String: AnyObject]
    
    init(dict: [String: AnyObject]) {
        self.dict = dict
    }
    
}

