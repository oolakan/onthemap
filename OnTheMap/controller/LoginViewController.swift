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
    var apiClient: ApiClient!
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
        context = appDelegate.persistentContainer.viewContext
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
                self.goHome()
            
        } catch {
            print("Unable to save")
        }
    }
    
    func getUser(_ userId: String) {
        apiClient = ApiClient()
        apiClient.getUser(userId: userId, completionHandler: {result in
            switch result {
            case .success(let user):
                print(user)
                if let user = user[Constants.UdacityResponseValues.user] as? NSDictionary
                {
                    performUIUpdatesOnMain {
                        self.saveUserData(user)
                    }
                }
            case .failure(let error):
                print(error)
               
                if !(self.presentingViewController?.isBeingDismissed)! {
                    self.dismiss(animated: true, completion: nil)
                     self.showAlert(title: "Message", message: error.localizedDescription)
                }
            }
        })
    }
    
    fileprivate func goHome() {
        performUIUpdatesOnMain {
            self.dismiss(animated: false, completion: nil)
            var controller: HomeViewController!
            controller = self.storyboard?.instantiateViewController(withIdentifier: "onthemap") as? HomeViewController
            self.present(controller, animated: true, completion: nil)
        }
      
    }
    
    @IBAction func doAuth(_ sender: Any) {
        let email = emailField.text
        let password = passwordField.text
        if !InternetConnection.isConnectedToNetwork() {
            self.showAlert(title: "Message", message: "No internet connection")
            return
        }
        if (email?.isEmpty)! {
            self.showAlert(title: "Message", message: "Enter your email address")
            return
        }
        if (password?.isEmpty)! {
            self.showAlert(title: "Message", message: "Enter your password")
            return
        }
        self.displayOverlay();
        apiClient = ApiClient()
        apiClient.doAuth(username: email!, password: password!, completionHandler: {result in
            switch result {
                case .success(let response):
                    print(response)
                    guard let account = response["account"] as? NSDictionary else
                    {
                        print("Error")
                        performUIUpdatesOnMain {
                            self.dismiss(animated: true, completion: nil)
                            self.showAlert(title: "Login Error", message: "Invalid username or password!")
                        }
                        return
                    }
                    let account_key = account["key"] as? String
                    performUIUpdatesOnMain {
                        self.accountKey = account_key!
                        let preferences = UserDefaults.standard
                        preferences.set(account_key, forKey: "account_key")
                        self.getUser(self.accountKey)
                        print("session id is\(self.accountKey)")
                    }
                case .failure(let error):
                    
                        self.dismiss(animated: true, completion: nil)
                        self.showAlert(title: "Message", message: error.localizedDescription)
                    
            }
        })
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
            view.frame.origin.y -= getKeyboardHeight(notification) - 40
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
    
    func showAlert(title: String, message: String)  {
        let actionSheetController = UIAlertController (title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheetController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
}
