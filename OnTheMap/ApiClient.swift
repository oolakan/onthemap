//
//  ApiClient.swift
//  OnTheMap
//
//  Created by Swifta on 3/18/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit
class ApiClient {
    var appDelegate: AppDelegate!
    var window: UIWindow?
    //https://stackoverflow.com/questions/44131678/completion-handler-swift-3-return-a-variable-from-function
    enum ConnectionResult {
        case success(NSDictionary)
        case failure(Error)
    }
    
    enum LocationResult {
        case success([Users])
        case failure(Error)
    }
    
    func getUser(userId: String, completionHandler: @escaping (_ serverResponse: ConnectionResult) -> Void ){
        let request = URLRequest(url: URL(string: Constants.Udacity.GET_USER_URL + userId)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            let range = Range(5..<data!.count)
            let newData = data?.subdata(in: range) /* subset response data! */
            print(String(data: newData!, encoding: .utf8)!)
            let json: Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: newData!, options: .allowFragments)
            }
            catch
            {
                print("Error parsing data");
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                print("Error parsing json")
                return
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(server_response))
            }
        }
        task.resume()
    }
    
    func doAuth(username: String, password: String, completionHandler: @escaping (_ serverResponse: ConnectionResult) -> Void ){
        var accountResponse: NSDictionary!
        let params: NSMutableDictionary = NSMutableDictionary()
        let _params: NSMutableDictionary = NSMutableDictionary()
        
        params.setValue(username, forKey: Constants.UdacityParameterKeys.USERNAME)
        params.setValue(password, forKey: Constants.UdacityParameterKeys.PASSWORD)
        _params.setValue(params, forKey: Constants.Udacity.udacityName)
        
        let jsonData = try! JSONSerialization.data(withJSONObject: _params, options: JSONSerialization.WritingOptions())
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        var url = URL(string: Constants.Udacity.SESSION_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = Constants.ParseParameterValues.POST_METHOD
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.ACCEPT)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        
        request.httpBody = jsonString?.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
            }
            var range: Any;
            let json: Any?
            do
            {
                range = Range(5..<data!.count)
                let newData = data?.subdata(in: range as! Range<Data.Index>) /* subset response data! */
                json = try JSONSerialization.jsonObject(with: newData!, options: .allowFragments)
            }
            catch
            {
                print("Error parsing data");
                completionHandler(.failure(error))
    
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                print("Error parsing json")
                return
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(server_response))
            }
        }
        task.resume()
    }
    
    
    func logout(completionHandler: @escaping (_ serverResponse: ConnectionResult) -> Void ) {
        var request = URLRequest(url: URL(string: Constants.Udacity.SESSION_URL)!)
        request.httpMethod = Constants.Udacity.DELETE_METHOD
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
            var json: Any
            do
            {
                let range = Range(5..<data!.count)
                let newData = data?.subdata(in: range ) /* subset response data! */
                print(String(data: newData!, encoding: .utf8)!)
                json = try JSONSerialization.jsonObject(with: newData!, options: .allowFragments)
            }
            catch
            {
                print("Error parsing data");
                completionHandler(.failure(error))
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                print("Error parsing json")
                return
            }
            guard let session = server_response["session"] as? NSDictionary else
            {
                print("Error")
                return
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(session))
            }
        }
        task.resume()
    }

    func getLocations(completionHandler: @escaping (_ users: LocationResult) -> Void){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let methodParameters = [
            Constants.ParseParameterKeys.LIMIT: 100,
            Constants.ParseParameterKeys.order: Constants.ParseParameterValues.sorted
            ] as [String : Any]
        
        let url = URL(string: Constants.Parse.STUDENT_LOCATIONS + self.escapedParameters(methodParameters as [String : AnyObject]))
        
        var request = URLRequest(url: url!)
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
                if let data = data {
                    let parseResult: NSDictionary!
                    do {
                        parseResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as!NSDictionary
                    }
                    catch {
                        self.displayError("Could not parse the data as JSON '\(data)'", url: url!)
                        return
                    }
                    guard let arrayOfResults = parseResult[Constants.ParseResponseValues.results] as? [[String:AnyObject]] else {
                        print("Cannot find key 'Basic' in \(parseResult)")
                        return
                    }
                    if arrayOfResults.count > 0 {
                        for result in arrayOfResults {
                            appDelegate.users.append(Users(dict: result))
                        }
                    }
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(appDelegate.users))
            }
        
        }
        task.resume()
    }
    
    
    fileprivate func prepareRequest(_ request: inout URLRequest, firstName: String, lastName: String, placeName: String, longitude: Double, latitude: Double) {
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.ACCEPT)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        
        
        let params: NSMutableDictionary = NSMutableDictionary()
        params.setValue(UserDefaults.standard.string(forKey: Constants.User.accountKey), forKey: Constants.ParseParameterKeys.UNIQUE_KEY)
        params.setValue(firstName, forKey: Constants.ParseParameterKeys.firstName)
        params.setValue(lastName, forKeyPath: Constants.ParseParameterKeys.lastName)
        params.setValue(placeName, forKey: Constants.ParseParameterKeys.mapString)
        params.setValue(longitude, forKey: Constants.ParseParameterKeys.longitude)
        params.setValue(latitude, forKey: Constants.ParseParameterKeys.latitude)
        
        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        request.httpBody = jsonString?.data(using: .utf8)
    }
    
    
    func postLocation(firstName: String, lastName: String, placeName: String, longitude: Double, latitude: Double, completionHandler: @escaping (_ serverResponse: ConnectionResult) -> Void ){
        var request = URLRequest(url: URL(string: Constants.Parse.STUDENT_LOCATION)!)
        request.httpMethod = Constants.ParseParameterValues.POST_METHOD
         self.prepareRequest(&request, firstName: firstName, lastName: lastName, placeName: placeName, longitude: longitude, latitude: latitude)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            print(String(data: data!, encoding: .utf8)!)
            let json: Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            }
            catch
            {
                print("Error parsing data");
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                print("Error parsing json")
                return
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(server_response))
            }
        }
        task.resume()
    }
    
    func updateLoation(locationObjectId: String, firstName: String, lastName: String, placeName: String, longitude: Double, latitude: Double, completionHandler: @escaping (_ serverResponse: ConnectionResult) -> Void ){
        var request = URLRequest(url: URL(string: Constants.Parse.STUDENT_LOCATIONS + "/" + locationObjectId)!)
        request.httpMethod = Constants.ParseParameterValues.PUT_METHOD
        self.prepareRequest(&request, firstName: firstName, lastName: lastName, placeName: placeName, longitude: longitude, latitude: latitude)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
        
            print(String(data: data!, encoding: .utf8)!)
            let json: Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            }
            catch
            {
                print("Error parsing data");
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                print("Error parsing json")
                return
            }
            if let error = error {
                completionHandler(.failure(error))
            }
            else {
                completionHandler(.success(server_response))
            }
        }
        task.resume()
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
    
    
    
    // if an error occurs, print it and re-enable the UI
    func displayError(_ error: String, url: URL) {
        print(error)
        print("URL at time of error: \(url)")
    }
    
    
    func escapedParametersForWhere(_ parameters: [String:AnyObject]) -> String {
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
    
    func showAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.window?.rootViewController = actionSheetController
        self.window?.makeKeyAndVisible()
    }
}
