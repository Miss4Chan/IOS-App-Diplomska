//
//  RegisterController.swift
//  ElderyCare
//
//  Created by Despina Misheva on 23.9.24.
//

import UIKit

class RegisterController: UIViewController {

    
    @IBOutlet weak var usernameTxt: UITextField!
    
    @IBOutlet weak var passwordTxt: UITextField!
    
    
    @IBOutlet weak var confirmPasswordTxt: UITextField!
    
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    @IBOutlet weak var firstNameTxt: UITextField!
    
    
    @IBOutlet weak var lastNameTxt: UITextField!
    
    
    @IBOutlet weak var emailTxt: UITextField!
    
    
    @IBOutlet weak var ErrorLabel: UILabel!
    
    @IBOutlet weak var imageLogo: UIImageView!
    
    @IBAction func registerClicked(_ sender: UIButton) {
        guard let username = usernameTxt.text, !username.isEmpty else {
                showError("Username is required")
                return
            }

            guard let password = passwordTxt.text, !password.isEmpty else {
                showError("Password is required")
                return
            }

            guard let confirmPassword = confirmPasswordTxt.text, password == confirmPassword else {
                showError("Passwords do not match")
                return
            }

            guard let firstName = firstNameTxt.text, !firstName.isEmpty else {
                showError("First name is required")
                return
            }

            guard let lastName = lastNameTxt.text, !lastName.isEmpty else {
                showError("Last name is required")
                return
            }

            guard let email = emailTxt.text, !email.isEmpty else {
                showError("Email is required")
                return
            }

            let dateOfBirth = datePicker.date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateOfBirthString = dateFormatter.string(from: dateOfBirth)

            APIManager.shared.register(username: username, password: password, firstName: firstName, lastName: lastName, email: email, dateOfBirth: dateOfBirthString) { result in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        print("Registration successful: \(user.username)")
                        self.navigateToMainViewController()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Registration failed: \(error.localizedDescription)")
                        self.showError("Registration failed: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    private func navigateToMainViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "Logo_elderly_care_supporting")
        imageLogo.image = image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showError(_ message: String) {
        ErrorLabel.text = message
        ErrorLabel.isHidden = false
        }
}
