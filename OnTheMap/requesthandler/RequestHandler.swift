//
//  RequestHandler.swift
//  OnTheMap
//
//  Created by Swifta on 3/7/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class RequestHandler {
    
    func getLocations() {
        let methodParameters = [
            Constants.ParseParameterKeys.LIMIT: 200,
            Constants.ParseParameterKeys.SKIP: 400
        ]
        
        let url = URL(string: Constants.Parse.STUDENT_LOCATION + self.escapedParameters(methodParameters as [String : AnyObject]))
        
        var request = URLRequest(url: url!)
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                self.displayError((error as? String)!, url: url!)
                return
            }
            else {
                if let data = data {
                    let parseResult: [String: AnyObject]!
                    do {
                        parseResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                    }
                    catch {
                        self.displayError("Could not parse the data as JSON '\(data)'", url: url!)
                        return
                    }
                    print(parseResult)
                }
            }
            print(String(data: data!, encoding: .utf8) as Any)
        }
        task.resume()
    }
    
    func getLocation() {
        let urlString = ""
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                return
            }
            print(String(data: data!, encoding: .utf8)!)
        }
        task.resume()
    }
    
    func postLocation() {
        var request = URLRequest(url: URL(string: Constants.Parse.STUDENT_LOCATION)!)
        request.httpMethod = Constants.ParseParameterValues.POST_METHOD
        request.httpBody = "{\"uniqueKey\": \"1234\", \"firstName\": \"John\", \"lastName\": \"Doe\",\"mapString\": \"Mountain View, CA\", \"mediaURL\": \"https://udacity.com\",\"latitude\": 37.386052, \"longitude\": -122.083851}".data(using: .utf8)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                return
            }
            print(String(data: data!, encoding: .utf8)!)
        }
        task.resume()
    }
    
    func updateLocation(objectId: String = "8ZExGR5uX8") {
        var url = URL(string: Constants.Parse.STUDENT_LOCATION + "/\(objectId)")
        var request = URLRequest(url: url!)
        
        request.httpMethod = Constants.ParseParameterValues.PUT_METHOD
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        
        request.httpBody = "{\"uniqueKey\": \"1234\", \"firstName\": \"John\", \"lastName\": \"Doe\",\"mapString\": \"Cupertino, CA\", \"mediaURL\": \"https://udacity.com\",\"latitude\": 37.322998, \"longitude\": -122.032182}".data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url!)")
                performUIUpdatesOnMain {
                    // self.setUIEnabled(true)
                }
            }
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            if error != nil {
                return
            }
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
    
    func auth() {
        self.displayOverlay();
        var request = URLRequest(url: URL(string: "")!)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.ACCEPT)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        request.httpBody = "{\"udacity\": {\"username\": \"opeoluwajoseph@gmail.com\", \"password\": \"Oluwatobi43\"}}".data(using: .utf8)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                return
            }
            let range = Range(5..<data!.count)
            let newData = data?.subdata(in: range) /* subset response data! */
            print(String(data: newData!, encoding: .utf8)!)
        }
        task.resume()
        
    }
    
    func logout() {
        var request = URLRequest(url: URL(string: Constants.Udacity.SESSION_URL)!)
        request.httpMethod = Constants.ParseParameterValues.DELETE_METHOD
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error…
                return
            }
            let range = Range(5..<data!.count)
            let newData = data?.subdata(in: range) /* subset response data! */
            print(String(data: newData!, encoding: .utf8)!)
        }
        task.resume()
    }
    
    func getUser(_ userId: String = "3903878747") {
        let request = URLRequest(url: URL(string: Constants.Udacity.GET_USER_URL + userId)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error...
                return
            }
            let range = Range(5..<data!.count)
            let newData = data?.subdata(in: range) /* subset response data! */
            print(String(data: newData!, encoding: .utf8)!)
        }
        task.resume()
    }
    
    // if an error occurs, print it and re-enable the UI
    func displayError(_ error: String, url: URL) {
        print(error)
        print("URL at time of error: \(url)")
        performUIUpdatesOnMain {
           // self.setUIEnabled(true)
        }
    }
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    
}
