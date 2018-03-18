//
//  LinkNameViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/10/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class LinkNameViewController: UIViewController , UITextFieldDelegate, MKMapViewDelegate{

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var linkTextField: UITextField!
 
    var annotation:MKAnnotation!
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    var error:NSError!
    var pointAnnotation:MKPointAnnotation!
    var pinAnnotationView:MKPinAnnotationView!
    
    var placeName: String!
    var firstName: String!
    var lastName: String!
    var uniqueKey: String!
    var _latitude: Double!//from coredata
    var _longitude: Double!//from coredata
    var latitude: Double!//from MKLocationsearch
    var longitude: Double!//from MkLocationSearch
    
    var studentLocation: NSManagedObject!
    var context : NSManagedObjectContext!
    
    var locationObjectId: String!
    
    var requestType: String!
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        getLocation(locationName: self.placeName)
        getUserData()
        getPreviousLocationObjectId()
        subscribeToKeyboardNotifications()
        configureTextField(textfield: linkTextField, withText: "Enter a link to share here")
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.navigateToLocationNamePage()
    }
    
    func navigateToLocationNamePage()  {
        let controller: LocationNameViewController!
        controller = self.storyboard?.instantiateViewController(withIdentifier: "locationname") as? LocationNameViewController
        controller.requestType = self.requestType
        self.present(controller, animated: true, completion: nil)
    }
    func getUserData()  {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Users")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                self.firstName = data.value(forKey: Constants.User.firstName) as! String
                self.lastName = data.value(forKey: Constants.User.lastName) as! String
                self.uniqueKey = data.value(forKey: Constants.User.uniqueKey) as! String
            }
        } catch {
            print("Failed")
        }
    }
    
    func getPreviousLocationObjectId()  {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.Location.locationEntityName)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let result = try self.context.fetch(fetchRequest)
            if result.count > 0 {
                for data in result as! [NSManagedObject] {
                    print(data.value(forKey: Constants.Location.objectId) as! String)
                    self.locationObjectId = data.value(forKey:Constants.Location.objectId) as! String
                }
                print("Previous Object id is\(self.locationObjectId)")
            }
        } catch {
            print("Failed")
        }
    }
    fileprivate func configureTextField(textfield: UITextField, withText text: String) {
        textfield.delegate = self
        textfield.text = text
    }
    
    func getLocation(locationName: String)  {
        
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = self.placeName
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in
            
            if localSearchResponse == nil{
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { (alertController) -> Void in
                   self.navigateToLocationNamePage()
                }))
                self.present(alertController, animated: true, completion: nil)
                return
            }
        
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = self.placeName
            self.pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude:     localSearchResponse!.boundingRegion.center.longitude)
            self.longitude = localSearchResponse!.boundingRegion.center.longitude
            self.latitude = localSearchResponse!.boundingRegion.center.latitude
             self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(self.pointAnnotation.coordinate, 1500, 1500), animated: true)
             let pin = PinAnnotation(title: self.placeName, subtitle: "", coordinate: self.pointAnnotation.coordinate)
            
            self.mapView.addAnnotation(pin)
        }
    }
    
    @IBAction func postOrUpdateLocation(){
        self.displayOverlay();
        if requestType.elementsEqual(Constants.ParseParameterValues.POST_METHOD) {
            self.postLocation()
        }
        else {
            self.updateLocation()
        }
    }
    
    func updateLocation() {
        var request = URLRequest(url: URL(string: Constants.Parse.STUDENT_LOCATIONS + "/" + self.locationObjectId)!)
        request.httpMethod = Constants.ParseParameterValues.PUT_METHOD
        self.prepareRequest(&request)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                return
            }
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
            print("updating..........")
          //  {"objectId":"PSaVGIUf5Z","createdAt":"2018-03-17T20:02:46.940Z"}
            if let updatedAt = server_response[Constants.Location.updatedAt] as? String
            {
                if !updatedAt.isEmpty {
                        performUIUpdatesOnMain {
                            self.dismiss(animated: false, completion: nil)
                            self.goHome()
                        }
                }
            }
            else {
                print("error occured")
            }
        }
        task.resume()
    }
   
    func postLocation() {
        var request = URLRequest(url: URL(string: Constants.Parse.STUDENT_LOCATION)!)
        request.httpMethod = Constants.ParseParameterValues.POST_METHOD
        self.prepareRequest(&request)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                return
            }
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
            if let objectId = server_response[Constants.Location.objectId] as? String
            {
                if !objectId.isEmpty {
                    let entity = NSEntityDescription.entity(forEntityName: Constants.Location.locationEntityName, in: self.context)
                    self.studentLocation = NSManagedObject(entity: entity!, insertInto: self.context)
                    self.studentLocation.setValue(objectId, forKey: Constants.Location.objectId)//save student location object id
                    do {
                        try self.context.save()
                        performUIUpdatesOnMain {
                                self.dismiss(animated: false, completion: nil)
                            self.goHome()
                        }
                    } catch {
                        print("Failed saving")
                    }
                    
                }
            }
            else {
                print("error occured")
            }
        }
        task.resume()
    }
    
    
    fileprivate func prepareRequest(_ request: inout URLRequest) {
        request.addValue(Constants.ParseParameterValues.PARSE_APPLICATION_ID, forHTTPHeaderField: Constants.ParseParameterKeys.PARSE_APPLICATION_ID)
        request.addValue(Constants.ParseParameterValues.REST_API_KEY, forHTTPHeaderField: Constants.ParseParameterKeys.REST_API_KEY)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.ACCEPT)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        
        
        let params: NSMutableDictionary = NSMutableDictionary()
        params.setValue(UserDefaults.standard.string(forKey: Constants.User.accountKey), forKey: Constants.ParseParameterKeys.UNIQUE_KEY)
        params.setValue(self.firstName, forKey: Constants.ParseParameterKeys.firstName)
        params.setValue(self.lastName, forKeyPath: Constants.ParseParameterKeys.lastName)
        params.setValue(self.placeName, forKey: Constants.ParseParameterKeys.mapString)
        params.setValue(self.longitude, forKey: Constants.ParseParameterKeys.longitude)
        params.setValue(self.latitude, forKey: Constants.ParseParameterKeys.latitude)
        
        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        request.httpBody = jsonString?.data(using: .utf8)
    }
    
   
    fileprivate func goHome() {
        var controller: HomeViewController!
        controller = self.storyboard?.instantiateViewController(withIdentifier: "onthemap") as? HomeViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        linkTextField.resignFirstResponder()
        return true
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if (linkTextField.isEditing) {
            self.view.frame.origin.y -= getKeyboardHeight(notification) - 40
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        //Hide the top navigation bar
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if linkTextField.isEditing {
            linkTextField.text = nil
        }
    
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
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
