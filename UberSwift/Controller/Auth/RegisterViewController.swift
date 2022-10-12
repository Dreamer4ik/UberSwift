//
//  RegisterViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 12.10.2022.
//

import UIKit

class RegisterViewController: UIViewController {
    
    // MARK: - Properties
    private var viewModel = RegistrationViewModel()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private let emailTextField = AuthField(type: .email)
    private let fullnameTextField = AuthField(type: .fullname)
    private let passwordTextField = AuthField(type: .password)
    
    private let signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Rider", "Driver"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .backgroundColor
        control.tintColor = UIColor(white: 1, alpha: 0.87)
        return control
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(
            string: "Already have an account?   ",
            attributes: [.font: UIFont.systemFont(ofSize: 16),
                         .foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(
            string: "Log In",
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
        view.addSubview(titleLabel)
        titleLabel.centerX(inView: view)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        configureContainerView()
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapDismiss))
        view.addGestureRecognizer(tap)
        
        alreadyHaveAccountButton.addTarget(self, action: #selector(didTapAlreadyHaveAccountButton), for: .touchUpInside)
    }
    
    private func configureContainerView() {
        guard let imageEmail = UIImage(named: "ic_mail_outline_white_2x") else { return }
        
        let emailContainerView = UIView().inputContainerView(image: imageEmail, textField: emailTextField)
        emailContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        guard let imageFullName = UIImage(named: "ic_person_outline_white_2x") else { return }
        
        let fullNameContainerView = UIView().inputContainerView(image: imageFullName, textField: fullnameTextField)
        fullNameContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        guard let imagePassword = UIImage(named: "ic_lock_outline_white_2x") else { return }
        
        let passwordContainerView = UIView().inputContainerView(image: imagePassword, textField: passwordTextField)
        passwordContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        guard let imageAccountType = UIImage(named: "ic_account_box_white_2x") else { return }
        
        let accountTypeContainerView = UIView().inputContainerView(image: imageAccountType,
                                                                   segmentedControl: accountTypeSegmentedControl)
        accountTypeContainerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,
                                                   fullNameContainerView,
                                                   passwordContainerView,
                                                   accountTypeContainerView,
                                                   signUpButton])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 24
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                     paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
    }
    
    private func checkFormStatus() {
        if viewModel.formIsValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = .mainBlueTint
            
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        }
    }
    
   private func configureTextFieldObservers() {
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        fullnameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    // MARK: - Actions
    
    @objc private func textDidChange(sender: UITextField) {
           if sender == emailTextField {
               viewModel.email = sender.text
           }
           else if sender == passwordTextField {
               viewModel.password = sender.text
           } else {
               viewModel.fullname = sender.text
           }
           checkFormStatus()
       }
    
    @objc private func didTapDismiss() {
        view.endEditing(true)
    }
    
    @objc private func didTapAlreadyHaveAccountButton() {
        navigationController?.popViewController(animated: true)
    }
    
}
