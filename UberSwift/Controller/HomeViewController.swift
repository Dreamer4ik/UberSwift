//
//  HomeViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 14.10.2022.
//

import UIKit
import Firebase
import MapKit

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

class HomeViewController: UIViewController {
    // MARK: - Properties
    
    private var user: User?
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private var searchResults = [MKPlacemark]()
    private var route: MKRoute?
    
    private final let heightLocationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    
    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    private var actionButtonConfig = ActionButtonConfiguration()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(LocationTableViewCell.self, forCellReuseIdentifier: LocationTableViewCell.identifier)
        table.register(LocationTableHeader.self, forHeaderFooterViewReuseIdentifier: LocationTableHeader.identifier)
        return table
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "baseline_menu_black_36dp")?.withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
   
    
    override func viewWillAppear(_ animated: Bool) {
        checkIfUserIsLoggedIn()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableLocationServices()
//        signOut()
    }
    
    // MARK: - API
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    private func fetchDrivers() {
        guard let location = locationManager?.location else {
            return
        }
        Service.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else {
                return
            }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisible: Bool {
                return self.mapView.annotations.contains { annotation in
                    guard let driverAnnotation = annotation as? DriverAnnotation else {
                        return false
                    }
                    
                    if driverAnnotation.uid == driver.uid {
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }
            
            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            presentLoginController()
        }
        else {
            configure()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            presentLoginController()
        }
        catch {
            print("Error signOut")
        }
    }
    // MARK: - Helpers
    
    private func configure() {
        configureUI()
        fetchUserData()
        fetchDrivers()
    }
    
    private func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(UIImage(
                named: "baseline_menu_black_36dp")?.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
           
        case .dismissActionView:
            actionButton.setImage(UIImage(named: "baseline_arrow_back_black_36dp")?.withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    private func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(
            x: 0,
            y: view.height,
            width: view.width,
            height: rideActionViewHeight
        )
    }
    
    private func configureUI() {
        configureMapView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingLeft: 20, width: 30, height: 30)
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        
        inputActivationView.delegate = self
        configureTable()
        
        let animator = UIViewPropertyAnimator(duration: 2, curve: .easeOut) {
            self.inputActivationView.alpha = 1
        }
        animator.startAnimation()
        
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }
    
    private func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    private func configureTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
        
        tableView.frame = CGRect(
            x: 0,
            y: view.height,
            width: view.width,
            height: view.height - heightLocationInputViewHeight
        )
        
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
                                 right: view.rightAnchor, height: heightLocationInputViewHeight)
        locationInputView.alpha = 0
        
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
            self.locationInputView.alpha = 1
        }
        let animator2 = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.tableView.frame.origin.y = self.heightLocationInputViewHeight
        }
        animator.addCompletion { _ in
            animator2.startAnimation()
        }
        animator.startAnimation()
        guard let user = user else {
            return
        }
        locationInputView.configureTitle(text: user.fullname.localizedCapitalized)
    }
    
    private func dismissLocationView(completion: (() -> Void)? = nil) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.height
            self.locationInputView.removeFromSuperview()
        }
        
        animator.addCompletion { _ in
            completion?()
        }
        animator.startAnimation()
    }
    
    private func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil) {
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        
        if shouldShow {
            guard let destination = destination else {
                return
            }
            rideActionView.configureLabel(placemark: destination)
        }
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        animator.startAnimation()
    }
    
    // MARK: - Actions
    
    @objc private func didTapActionButton() {
        switch actionButtonConfig {
        case .showMenu:
            print("Show menu")
        case .dismissActionView:
            
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
            animator.startAnimation()
        }
    }
    
}

// MARK: - MapView Helper Functions

private extension HomeViewController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else { return }
            
            response.mapItems.forEach({ item in
                results.append(item.placemark)
            })
            
            completion(results)
        }
    }
    
    func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { response, error in
            guard let response = response else {
                return
            }
            
            self.route = response.routes[0]
            
            guard let polyline = self.route?.polyline else {
                return
            }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
}

// MARK: - MKMapViewDelegate
extension HomeViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? DriverAnnotation else {
            return nil
        }
        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: DriverAnnotation.identifier)
        let image = UIImage(named: "car_icon")?.resizeWithScaleAspectFitMode(to: 47)
        view.image = image
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(polyline: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 3
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}
// MARK: - Location Services
extension HomeViewController {
    private func enableLocationServices() {
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14, *) {
            guard let locationManager = locationManager else {
                return
            }
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus {
        case .notDetermined:
            print("notDetermined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted,.denied:
            break
        case .authorizedAlways:
            print("authorizedAlways")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
            locationManager?.requestAlwaysAuthorization()
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
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView {
            let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
                self.inputActivationView.alpha = 1
            }
            animator.startAnimation()
        }
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
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LocationTableViewCell.identifier,
            for: indexPath
        ) as? LocationTableViewCell else {
            preconditionFailure("LocationTableViewCell error")
        }
        
        if indexPath.section == 1 {
            let placemark = searchResults[indexPath.row]
            cell.configureLabel(placemark: placemark)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView {
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            let annotations = self.mapView.annotations.filter {
                !$0.isKind(of: DriverAnnotation.self)
            }
            
            self.mapView.zoomToFit(annotations: annotations)
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark)
        }
        
       
    }
}
