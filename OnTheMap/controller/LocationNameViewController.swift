//
//  LoationNameViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/10/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LocationNameViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var findonMapBtn: UIButton!
    @IBOutlet weak var locationName: UITextField!
    var requestType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToKeyboardNotifications()
        configureTextField(textfield: locationName, withText: "Enter your location here")
    }
    @IBAction func navigateToStudentUrlPage()  {
        let controller: LinkNameViewController!
        controller = self.storyboard?.instantiateViewController(withIdentifier: "studenturl") as? LinkNameViewController
        controller.placeName = locationName.text
        controller.requestType = self.requestType
        self.present(controller, animated: true, completion: nil)
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
}
