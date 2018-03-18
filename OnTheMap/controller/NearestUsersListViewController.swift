//
//  NearestUsersListViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/10/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NearestUsersListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var addPin: UIBarButtonItem!
    @IBOutlet weak var refresh: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var users = [Users]()
    var reuseIdentifier: String = "nearestusercell"
    var locationObjectId: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getLocations()
        tableView.dataSource = self
        tableView.delegate = self
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NearestUserTableViewCell else {
            return UITableViewCell()
        }
        cell.userName.text = "\(self.users[indexPath.row].firstName) \(self.users[indexPath.row].lastName)"
        cell.pin.image = UIImage(named: "icon_pin")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //https://stackoverflow.com/questions/25945324/swift-open-link-in-safari
        guard let url = URL(string: self.users[indexPath.row].mediaURL as! String) else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func refreshStudentLocations(_ sender: Any) {
        self.getLocations()
    }
    func getLocations() {
        self.displayOverlay();
        let methodParameters = [
            Constants.ParseParameterKeys.LIMIT: 20,
            Constants.ParseParameterKeys.SKIP: 400
        ]
        
        let url = URL(string: Constants.Parse.STUDENT_LOCATIONS + self.escapedParameters(methodParameters as [String : AnyObject]))
        
        var request = URLRequest(url: url!)
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                // self.displayError((error as? String)!, url: url!)
                return
            }
            else {
                if let data = data {
                    let parseResult: NSDictionary!
                    do {
                        parseResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as!NSDictionary
                    }
                    catch {
                        self.displayError("Could not parse the data as JSON '\(data)'", url: url!)
                        return
                    }
                    //                    print(parseResult)
                    guard let arrayOfResults = parseResult[Constants.ParseResponseValues.results] as? [[String:AnyObject]] else {
                        print("Cannot find key 'Basic' in \(parseResult)")
                        return
                    }
                    if arrayOfResults.count > 0 {
                        self.users = [Users]()//reinitialize user
                        for result in arrayOfResults {
                            let user = Users(firstName: result[Constants.ParseResponseValues.firstName] as! String,
                                             lastName: result[Constants.ParseResponseValues.lastName] as! String,
                                             latitude: result[Constants.ParseResponseValues.latitude] as! Double,
                                             longitude: result[Constants.ParseResponseValues.longitude] as! Double,
                                             mapString: result[Constants.ParseResponseValues.mapString] as! String,
                                             mediaURL: result[Constants.ParseResponseValues.mediaURL] as! String,
                                             objectId: result[Constants.ParseResponseValues.objectId] as! String,
                                             uniqueKey: result[Constants.ParseResponseValues.uniqueKey] as! String)
                            self.users.append(user)
                        }
                    }
                    performUIUpdatesOnMain {
                        self.dismiss(animated: false, completion: nil)
                        self.tableView.reloadData()
                    }
                }
            }
            print(String(data: data!, encoding: .utf8) as Any)
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
    
    
    
    fileprivate func goToLocationNameViewController(requestType: String) {
        var controller: LocationNameViewController!
        controller = self.storyboard?.instantiateViewController(withIdentifier: "locationname") as? LocationNameViewController
        controller.requestType = requestType
        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func checkIfLocationPosted() {
        //get location objectId
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.Location.locationEntityName)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(fetchRequest)
            if result.count > 0 {
                for data in result as! [NSManagedObject] {
                    print(data.value(forKey: Constants.User.objectId) as! String)
                    self.locationObjectId = data.value(forKey: Constants.User.objectId) as! String
                }
            }
        } catch {
            print("Failed")
        }
        if self.locationObjectId != nil {
            let message = "You have already posted a student location, would you like to overwrite your current location?"
            self.showAlert(message: message)
        }
        else{
            self.goToLocationNameViewController(requestType: Constants.ParseParameterValues.POST_METHOD)
        }
        
    }
    //https://stackoverflow.com/questions/24190277/writing-handler-for-uialertaction
    func showAlert(message: String)  {
        let actionSheetController = UIAlertController (title: "My Action Title", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        actionSheetController.addAction(UIAlertAction(title: "Update", style: UIAlertActionStyle.default, handler: { (actionSheetController) -> Void in
            self.goToLocationNameViewController(requestType: Constants.ParseParameterValues.PUT_METHOD)
        }))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // if an error occurs, print it and re-enable the UI
    func displayError(_ error: String, url: URL) {
        print(error)
        print("URL at time of error: \(url)")
    }
    
    //https://stackoverflow.com/questions/27960556/loading-an-overlay-when-running-long-tasks-in-ios
    func displayOverlay()  {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
}