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
    private let locationManager = CLLocationManager()
    private let heightLocationInputView: CGFloat = 200
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(LocationTableViewCell.self, forCellReuseIdentifier: LocationTableViewCell.identifier)
        table.register(LocationTableHeader.self, forHeaderFooterViewReuseIdentifier: LocationTableHeader.identifier)
        return table
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            configureUI()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
        //        signOut()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(
            x: 0,
            y: view.height,
            width: view.width,
            height: view.height - heightLocationInputView
        )
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
        configureMapView()
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.width - 64)
        inputActivationView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        
        inputActivationView.delegate = self
        configureTable()
        
        let animator = UIViewPropertyAnimator(duration: 2, curve: .easeOut) {
            self.inputActivationView.alpha = 1
        }
        animator.startAnimation()
    }
    
    private func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    private func configureTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
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
    
    func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: heightLocationInputView)
        locationInputView.alpha = 0
        
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
            self.locationInputView.alpha = 1
        }
        let animator2 = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.tableView.frame.origin.y = self.heightLocationInputView
        }
        animator.addCompletion { _ in
            animator2.startAnimation()
        }
        animator.startAnimation()
    }
    
    // MARK: - Actions
    
}
// MARK: - Location Services
extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    private func enableLocationServices() {
        locationManager.delegate = self
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus {
        case .notDetermined:
            print("notDetermined")
            locationManager.requestWhenInUseAuthorization()
        case .restricted,.denied:
            break
        case .authorizedAlways:
            print("authorizedAlways")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            preconditionFailure("Error enableLocationServices")
        }
    }
}
// MARK: - LocationInputActivationViewDelegate
extension HomeViewController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

extension HomeViewController: LocationInputViewDelegate {
    func dismissLocationInputView() {
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.height
        }
        let animator2 = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.locationInputView.removeFromSuperview()
            self.inputActivationView.alpha = 1
        }
        animator.addCompletion { _ in
            animator2.startAnimation()
        }
        animator.startAnimation()
    }
    
}
// MARK: - TableViewDelegate
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: LocationTableHeader.identifier) as? LocationTableHeader else {
            return UIView()
        }
        
        if section == 0 {
            header.configure(with: "Saved Locations")
        }
        else {
            header.configure(with: "Results")
        }
        return header
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LocationTableViewCell.identifier,
            for: indexPath
        ) as? LocationTableViewCell else {
            preconditionFailure("LocationTableViewCell error")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
