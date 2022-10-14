//
//  HomeViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 14.10.2022.
//

import UIKit
import Firebase
import MapKit

class HomeViewController: UIViewController {
    // MARK: - Properties
    
    private let mapView = MKMapView()
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            configureUI()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
//        signOut()
    }
    
    // MARK: - API
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            presentLoginController()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print("Error signOut")
        }
    }
    // MARK: - Helpers
    
    private func configureUI() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
    }
    
    private func presentLoginController() {
        DispatchQueue.main.async {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            if #available(iOS 13.0, *) {
                nav.isModalInPresentation = true
            }
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    // MARK: - Actions
    
}
