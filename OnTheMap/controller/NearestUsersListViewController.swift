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
 
    var reuseIdentifier: String = "nearestusercell"
    var locationObjectId: String!
    var appDelegate: AppDelegate!
    var apiClient: ApiClient!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getLocations()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    fileprivate func getStudentLocations() {
        if !InternetConnection.isConnectedToNetwork() {
            self.showErrorAlert(title: "Message", message: "No internet connection")
            return
        }
        displayIndicator()
        apiClient = ApiClient()
        apiClient.getLocations(completionHandler: { studentsLocation in
            switch studentsLocation {
            case .success(let students):
                print(students)
                performUIUpdatesOnMain {
                    if students.studentInfo.count > 0 { //data already saved in appdelegate
                        for student in students.studentInfo {
                            StudentDataSource.shared.studentInfo.append(student)
                            self.dismiss(animated: true, completion: nil)
                        }
                        self.tableView.reloadData()
                    }
                    else {
                        if !(self.presentingViewController?.isBeingDismissed)! {
                            self.dismiss(animated: false, completion: nil)
                            self.showErrorAlert(title: "Message", message: "No student location found")
                        }
                    }
                }
            case .failure(let error):
                print(error)
                if !(self.presentingViewController?.isBeingDismissed)! {
                    self.dismiss(animated: false, completion: nil)
                    self.showErrorAlert(title: "Message", message: error.localizedDescription)
                }
            }
        })
    }
    
    @IBAction func refresh(_ sender: Any) {
        getStudentLocations()
    }
    @IBAction func logout(_ sender: Any) {
        if !InternetConnection.isConnectedToNetwork() {
            self.showErrorAlert(title: "Message", message: "No internet connection")
            return
        }
        self.displayIndicator()
        let apiClient = ApiClient()
        apiClient.logout(completionHandler: { response in
            switch response {
            case .success(let res):
                let id = res["id"] as! String
                if !id.isEmpty {
                    performUIUpdatesOnMain {
                        self.dismiss(animated: true, completion: nil)//dismiss overlay
                        UserDefaults.standard.set("", forKey: "account_key")//empty storage
                        self.deleteAllData(entity: Constants.User.userEntityName)
                    }
                   
                }
            case .failure(let error):
                print(error)
                if (self.presentingViewController?.isBeingDismissed)! {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        })
    }
    //https://stackoverflow.com/questions/24658641/ios-delete-all-core-data-swift/38449688
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let userData = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
        do {
            try managedContext.execute(userData)
            self.dismiss(animated:true)//dismiss view controller
            
        }
        catch {
            print(error)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentDataSource.shared != nil ? StudentDataSource.shared.studentInfo.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NearestUserTableViewCell else {
            return UITableViewCell()
        }
        cell.userName.text = "\(StudentDataSource.shared.studentInfo[indexPath.row].dict[Constants.ParseResponseValues.firstName] as! String)\(StudentDataSource.shared.studentInfo[indexPath.row].dict[Constants.ParseResponseValues.lastName] as! String)"
        
        cell.pin.image = UIImage(named: "icon_pin")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: StudentDataSource.shared.studentInfo[indexPath.row].dict[Constants.ParseResponseValues.mediaURL] as! String ) else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func getLocations() {
        getStudentLocations()
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
    
    func showErrorAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    //https://stackoverflow.com/questions/27960556/loading-an-overlay-when-running-long-tasks-in-ios
    func displayIndicator()  {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
}
