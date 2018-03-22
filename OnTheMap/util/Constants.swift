//
//  Constants.swift
//  OnTheMap
//
//  Created by Swifta on 3/7/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct Constants {
   // Parse Application ID: QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr
   // REST API Key: QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY
    // Parse
    
    struct Location {
        static let locationEntityName = "Location"
        static let objectId = "objectId"
        static let updatedAt = "updatedAt"
    }
    struct User {
        static let userEntityName = "Users"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let objectId = "objectId"
        static let uniqueKey = "uniqueKey"
        static let accountKey = "account_key"
    }
    struct Parse {
        static let APIBaseURL = "https://parse.udacity.com/parse/classes/"
        static let STUDENT_LOCATIONS = Parse.APIBaseURL + "StudentLocation"
        static let STUDENT_LOCATION = Parse.APIBaseURL + "StudentLocation?where="
    }
    
    struct Udacity {
        static let udacityName = "udacity"
        static let APIBaseURL = "https://www.udacity.com/api/"
        static let SESSION_URL = Udacity.APIBaseURL + "session"
        static let GET_USER_URL = Udacity.APIBaseURL + "users/"
        static let DELETE_METHOD = "DELETE"
    }
    
    // MARK: Parse Parameter Keys
    struct ParseParameterKeys {
        static let Method = "method"
        static let PARSE_APPLICATION_ID = "X-Parse-Application-Id"
        static let REST_API_KEY = "X-Parse-REST-API-Key"
        static let LIMIT = "limit"
        static let SKIP = "skip" //page
        static let CONTENT_TYPE = "Content-Type"
        static let ACCEPT = "Accept"
        static let UNIQUE_KEY = "uniqueKey"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let userId = "userId"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let mapString = "mapString"
        static let order = "order"
       
    }
    
    
    struct UdacityParameterKeys {
        static let USERNAME = "username"
        static let PASSWORD = "password"
    }
    
    struct UdacityResponseValues {
        static let USERNAME = "username"
        static let PASSWORD = "password"
        static let firstName = "first_name"
        static let lastName = "last_name"
        static let user = "user"
    }
    
    
    // MARK: Parse Parameter Values
    struct ParseParameterValues {
        static let POST_METHOD = "POST"
        static let PUT_METHOD = "PUT"
        static let GET_METHOD = "GET"
        static let DELETE_METHOD = "DELETE"
        
        static let PARSE_APPLICATION_ID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let REST_API_KEY = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
        static let ResponseFormat = "json"
        static let CONTENT_TYPE_FORMAT = "application/json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let sorted = "-updatedAt"
    }
    
    // MARK: Parse Response Keys
    struct ParseResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
       
    }
    
    // MARK: Parse Response Values
    struct ParseResponseValues {
        static let OKStatus = "ok"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let userId = "userId"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let mapString = "mapString"
        static let objectId = "objectId"
        static let mediaURL = "mediaURL"
        static let uniqueKey = "uniqueKey"
        static let results = "results"
    }
}
