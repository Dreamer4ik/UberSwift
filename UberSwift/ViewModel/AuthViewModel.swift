//
//  AuthViewModel.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 12.10.2022.
//

import Foundation

protocol AuthenticationViewModelProtocol {
    var formIsValid: Bool { get }
}

struct LoginViewModel: AuthenticationViewModelProtocol {
    var email: String?
    var password: String?
    
    var formIsValid: Bool {
        return email?.isEmpty == false &&
        password?.isEmpty == false
    }
}

struct RegistrationViewModel: AuthenticationViewModelProtocol {
    var email: String?
    var fullname: String?
    var password: String?
    
    var formIsValid: Bool {
        return email?.isEmpty == false &&
        password?.isEmpty == false &&
        fullname?.isEmpty == false
    }
}
