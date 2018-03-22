//
//  LoationNameViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/10/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
class LocationNameViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var findonMapBtn: UIButton!
    @IBOutlet weak var locationName: UITextField!
    var requestType: String!
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToKeyboardNotifications()
        configureTextField(textfield: locationName, withText: "Enter your location here")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    @IBAction func navigateToStudentUrlPage()  {
       getLocation(locationName: locationName.text!)
    }
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    func showActivityIndicatory()  {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func dismissIndicator() {
        
            self.dismiss(animated: true, completion: nil)
        
    }
    
    func getLocation(locationName: String)  {
     //   displayOverlay()
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = locationName
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in
            //self.dismissIndicator()
            if localSearchResponse == nil{
                
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
                let longitude = localSearchResponse!.boundingRegion.center.longitude
                let latitude = localSearchResponse!.boundingRegion.center.latitude
            
            
                     let controller: LinkNameViewController!
                    controller = self.storyboard?.instantiateViewController(withIdentifier: "studenturl") as? LinkNameViewController
                    controller.placeName = locationName
                    controller.requestType = self.requestType
                    controller.longitude = longitude
                    controller.latitude = latitude
                    self.present(controller, animated: true, completion: nil)
                
            
            
        }
    }
    fileprivate func configureTextField(textfield: UITextField, withText text: String) {
        textfield.delegate = self
        textfield.text = text
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        locationName.resignFirstResponder()
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
        if (locationName.isEditing) {
            self.view.frame.origin.y -= getKeyboardHeight(notification) - 100
        }
    }
    @objc func keyboardWillHide(_ notification: Notification) {
        //Hide the top navigation bar
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if locationName.isEditing {
            locationName.text = nil
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
