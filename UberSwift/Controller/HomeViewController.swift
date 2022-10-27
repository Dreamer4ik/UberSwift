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
    
    private var user: User? {
        didSet {
            guard let user = user else { return }
            if user.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            }
            else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = user else { return }
            
            if user.accountType == .driver {
                guard let trip = trip else { return }
                
                let vc = PickupViewController(trip: trip)
                vc.delegate = self
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
            else {
                print("Show ride action view for accepted trip..")
            }
            
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        checkIfUserIsLoggedIn()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser?.uid != nil && user == nil {
            fetchUserData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(config), name: NSNotification.Name(rawValue: "AuthFetchData"), object: nil)
        
        enableLocationServices()
//        signOut()
    }
    
    // MARK: - API
    
    private func observeCurrentTrip() {
        Service.shared.observeCurrentTrip { trip in
            self.trip = trip
            
            if trip.state == .accepted {
                print("Trip was accept")
                self.shouldPresentLoadingView(false)
                
                guard let driverUid = trip.driverUid else {
                    return
                }
                
                Service.shared.fetchUserData(uid: driverUid) { [weak self] driver in
                    self?.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
                
                
            }
        }
    }
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    private func fetchDrivers() {
        guard let location = locationManager?.location,
              user?.accountType == .passenger else {
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
    
    private func observeTrips() {
        Service.shared.observeTrips { trip in
            self.trip = trip
        }
    }
    
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            presentLoginController()
        }
        else {
             configureUI()
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
        rideActionView.delegate = self
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
        
        configureTable()
        
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
    
    private func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.inputActivationView.alpha = 1
        }
        animator.startAnimation()
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
    
    private func animateRideActionView(
        shouldShow: Bool,
        destination: MKPlacemark? = nil,
        config: RideActionViewConfiguration? = nil,
        user: User? = nil
    ) {
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        animator.startAnimation()
        
        if shouldShow {
            if let user = user {
                rideActionView.user = user
            }
            
            if let destination = destination {
                rideActionView.configureLabel(placemark: destination)
            }
            
            if let config = config {
                rideActionView.configureUI(withConfig: config)
            }
        }
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
    
    @objc private func config() {
        fetchUserData()
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
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

// MARK: - RideActionViewDelegate
extension HomeViewController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate,
              let destinationCoordinates = view.destination?.coordinate else {
            return
        }
        
        shouldPresentLoadingView(true, message: "Finding you a ride...")
        
        Service.shared.uploadTrip(pickupCoordinates: pickupCoordinates,
                                  destinationCoordinates: destinationCoordinates) { error, ref in
            if let error = error {
                print("Failed to upload trip with error")
                return
            }
            
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
            animator.startAnimation()
            
            print("Did upload trip successfully")
        }
    }
}

// MARK: - PickupViewControllerDelegate
extension HomeViewController: PickupViewControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { [weak self] passenger in
                self?.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
