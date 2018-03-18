//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Swifta on 3/6/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    var accountKey:String = ""
    
    var newUser: NSManagedObject!
    var context : NSManagedObjectContext!
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBtn()
        subscribeToKeyboardNotifications()
        configureTextField(textfield: emailField, withText: "Enter Username")
        configureTextField(textfield: passwordField, withText: "Enter Password")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func configureBtn() {
        signUpBtn.layer.borderColor = UIColor.clear.cgColor
        signUpBtn.layer.borderWidth = 2
        signUpBtn.layer.cornerRadius = 5
    }
    
    fileprivate func configureTextField(textfield: UITextField, withText text: String) {
        textfield.delegate = self
        textfield.text = text
    }
    
    fileprivate func saveUserData(_ user: NSDictionary) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: Constants.User.userEntityName, in: self.context)
        self.newUser = NSManagedObject(entity: entity!, insertInto: self.context)
        
        let lastName = user[Constants.UdacityResponseValues.lastName] as? String
        let firstName = user[Constants.UdacityResponseValues.firstName] as? String
        let uniqueKey = UserDefaults.standard.string(forKey: Constants.User.accountKey)
        self.newUser.setValue(firstName, forKey: Constants.User.firstName)
        self.newUser.setValue(lastName, forKey: Constants.User.lastName)
        self.newUser.setValue(uniqueKey, forKey: Constants.User.uniqueKey)
        do {
            try self.context.save()
        } catch {
            print("Unable to save")
        }
    }
    
    func getUser(_ userId: String) {
        let request = URLRequest(url: URL(string: Constants.Udacity.GET_USER_URL + userId)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error...
                return
            }
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
            print(server_response)
            if let user = server_response[Constants.UdacityResponseValues.user] as? NSDictionary
            {
                performUIUpdatesOnMain {
                    self.saveUserData(user)
                    self.dismiss(animated: false, completion: nil)
                    self.goHome()
                }
            }
        }
        task.resume()
    }
    
    fileprivate func goHome() {
        var controller: HomeViewController!
        controller = self.storyboard?.instantiateViewController(withIdentifier: "onthemap") as? HomeViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func doAuth(_ sender: Any) {
        self.displayOverlay();
        let params: NSMutableDictionary = NSMutableDictionary()
        let _params: NSMutableDictionary = NSMutableDictionary()
        params.setValue(emailField.text, forKey: Constants.UdacityParameterKeys.USERNAME)
        params.setValue(passwordField.text, forKey: Constants.UdacityParameterKeys.PASSWORD)
        _params.setValue(params, forKey: Constants.Udacity.udacityName)
        let jsonData = try! JSONSerialization.data(withJSONObject: _params, options: JSONSerialization.WritingOptions())
        let jsonString = String(data: jsonData, encoding: .utf8)

        var url = URL(string: Constants.Udacity.SESSION_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = Constants.ParseParameterValues.POST_METHOD
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.ACCEPT)
        request.addValue(Constants.ParseParameterValues.CONTENT_TYPE_FORMAT, forHTTPHeaderField: Constants.ParseParameterKeys.CONTENT_TYPE)
        
        request.httpBody = jsonString?.data(using: .utf8)
        //jsonString?.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
            }
            if error != nil {
                return
            }
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
            if let account = server_response["account"] as? NSDictionary
            {
                if let account_key = account["key"] as? String
                {
                    performUIUpdatesOnMain {
                        self.accountKey = account_key
                        let preferences = UserDefaults.standard
                        preferences.set(account_key, forKey: "account_key")
                        if !(preferences.string(forKey: "account_key")?.isEmpty)! {
                            self.getUser(self.accountKey)
                        }
                        else {
                            print("Value not saved")
                        }
                    }
                    print("session id is\(account_key)")
                }
            }
        }
        task.resume()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
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
        if (passwordField.isEditing) {
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
        if emailField.isEditing {
            emailField.text = nil
        }
        if passwordField.isEditing {
            passwordField.text = nil
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
