//
//  NearestUsersMapViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/10/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class NearestUsersMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
     @IBOutlet weak var mapView: MKMapView!
    let annotation = MKPointAnnotation()
    var appDelegate: AppDelegate!
    var locationObjectId: String!
    
    var apiClient: ApiClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLocations()
        self.locationManager.delegate = self
        mapView.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
         self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(center, 1500, 1500), animated: true)
         let pin = PinAnnotation(title: "", subtitle: "", coordinate: center)
         self.mapView.addAnnotation(pin)
        self.locationManager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors " + error.localizedDescription)
    }
    
    @IBAction func logout(_ sender: Any) {
        if !InternetConnection.isConnectedToNetwork() {
            self.showErrorAlert(title: "Message", message: "No internet connection")
            return
        }
        self.displayOverlay()
        let apiClient = ApiClient()
        apiClient.logout(completionHandler: { response in
            switch response {
            case .success(let res):
                let id = res["id"] as! String
                if !id.isEmpty {
                    performUIUpdatesOnMain {
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
    
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let userData = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
        do {
            try managedContext.execute(userData)
            performUIUpdatesOnMain {
                self.dismiss(animated: true, completion: {
                    var controller: LoginViewController!
                    controller = self.storyboard?.instantiateViewController(withIdentifier: "login") as? LoginViewController
                    self.present(controller, animated: true, completion: nil)
                })
            }
        }
        catch {
            print(error)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        if let annotation = view.annotation as? PinAnnotation
        {
            //https://stackoverflow.com/questions/25945324/swift-open-link-in-safari
            guard let url = URL(string: annotation.subtitle! ) else {
                return
            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func refreshStudentLocations(_ sender: Any) {
        self.getLocations()
    }
    
    func getLocations() {
        if !InternetConnection.isConnectedToNetwork() {
            self.showErrorAlert(title: "Message", message: "No internet connection")
            return
        }
        displayOverlay()
        apiClient = ApiClient()
        apiClient.getLocations(completionHandler: { studentsLocation in
            switch studentsLocation {
            case .success(let students):
                print(students)
                  performUIUpdatesOnMain {
                    self.dismiss(animated: false, completion: nil)
                    if students.count > 0 {
                     print("Result is greater than 0")
                        for student in students {
                            let locationCordinate = CLLocationCoordinate2DMake(student.dict[Constants.ParseResponseValues.latitude] as! Double, student.dict[Constants.ParseResponseValues.longitude] as! Double )
                            
                            let title = student.dict[Constants.ParseResponseValues.firstName] as! String
                            if let url = student.dict[Constants.ParseResponseValues.mediaURL] {
                                self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(locationCordinate, 1500, 1500), animated: true)
                                let pin = PinAnnotation(title:  title, subtitle: url as! String , coordinate: locationCordinate)
                                self.mapView.addAnnotation(pin)
                            }
                        }
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
    
    func showErrorAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
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
