//
//  LoginController.swift
//  ElderyCare
//
//  Created by Despina Misheva on 23.9.24.
//

import UIKit

class LoginController: UIViewController {
    
    @IBOutlet weak var usernameTxt: UITextField!
    
    @IBOutlet weak var passwordTxt: UITextField!
    
    
    @IBOutlet weak var ErrorLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ErrorLabel.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func loginClicked(_ sender: UIButton) {
        guard let username = usernameTxt.text, !username.isEmpty else {
                showError("Username is required")
                return
            }

            guard let password = passwordTxt.text, !password.isEmpty else {
                showError("Password is required")
                return
            }
        
            APIManager.shared.login(username: username, password: password) { result in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        print("Logged in user: \(user.username), token: \(user.token)")
                        self.navigateToMainViewController()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.showError("Login failed: \(error.localizedDescription)")
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
   
    private func showError(_ message: String) {
        ErrorLabel.text = message
        ErrorLabel.isHidden = false
        }
}
