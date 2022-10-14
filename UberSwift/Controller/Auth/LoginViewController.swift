//
//  LoginViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 11.10.2022.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private var viewModel = LoginViewModel()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private let emailTextField = AuthField(type: .email)
    private let passwordTextField = AuthField(type: .password)
    
    private let loginButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    let haveNotAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(
            string: "Don't have an account?   ",
            attributes: [.font: UIFont.systemFont(ofSize: 16),
                         .foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(
            string: "Sign Up",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16),
                         .foregroundColor: UIColor.mainBlueTint]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFieldObservers()
        configureUI()
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        view.backgroundColor = .backgroundColor
        configureNavigationBar()
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        
        configureContainerView()
        
        view.addSubview(haveNotAccountButton)
        haveNotAccountButton.centerX(inView: view)
        haveNotAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapDismiss))
        view.addGestureRecognizer(tap)
        
        haveNotAccountButton.addTarget(self, action: #selector(didTapHaveNotAccountButton), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
    }
    
    private func configureContainerView() {
        guard let imageEmail = UIImage(named: "ic_mail_outline_white_2x") else { return }
        
        let emailContainerView = UIView().inputContainerView(image: imageEmail, textField: emailTextField)
        emailContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        guard let imagePassword = UIImage(named: "ic_lock_outline_white_2x") else { return }
        
        let passwordContainerView = UIView().inputContainerView(image: imagePassword, textField: passwordTextField)
        passwordContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView, loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 24
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                     paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    
    private func checkFormStatus() {
        if viewModel.formIsValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = .mainBlueTint
            
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        }
    }
    
    private func configureTextFieldObservers() {
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    // MARK: - Actions
    
    @objc private func didTapLogin() {
        guard let email = emailTextField.text?.lowercased(),
              let password = passwordTextField.text else {
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Failed to log user with error \(error.localizedDescription)")
                return
            }
            
            self?.dismiss(animated: true)
            print("Successfully logged user...")
            
        }
    }
    
    @objc private func didTapHaveNotAccountButton() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapDismiss() {
        view.endEditing(true)
    }
    
    @objc private func textDidChange(sender: UITextField) {
           if sender == emailTextField {
               viewModel.email = sender.text
           }
           else if sender == passwordTextField {
               viewModel.password = sender.text
           }
           checkFormStatus()
       }
}
