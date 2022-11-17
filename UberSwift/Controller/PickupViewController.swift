//
//  PickupViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 24.10.2022.
//

import UIKit
import MapKit

protocol PickupViewControllerDelegate: AnyObject {
    func didAcceptTrip(_ trip: Trip)
}

class PickupViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: PickupViewControllerDelegate?
    private let mapView = MKMapView()
    private var circularProgressView: CircularProgressView = {
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let cp = CircularProgressView(frame: frame)
        return cp
    }()
    let trip: Trip
    var timer: Timer?
    private var totalSeconds = 0
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "baseline_clear_white_36pt_2x")?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "Would you like to pickup this passenger?"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private let acceptTripButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("ACCEPT TRIP", for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureMapView()
        
        self.perform(#selector(animateProgress), with: nil, afterDelay: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startTimer()
        }
        
        cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        acceptTripButton.addTarget(self, action: #selector(didTapAcceptButton), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Helpers
    
    private func configureMapView() {
        let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
    }
    
    private func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingLeft: 16)
        
        view.addSubview(circularProgressView)
        circularProgressView.setDimensions(height: 360, width: 360)
        circularProgressView.centerX(inView: view)
        circularProgressView.addSubview(mapView)
        
        let topPadding: CGFloat
        if #unavailable(iOS 15) {
            topPadding = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        } else {
            topPadding = UIApplication
                .shared
                .connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }?.safeAreaInsets.top ?? 0
        }
        circularProgressView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: topPadding)
        
        let mapSize: CGFloat = 268
        mapView.setDimensions(height: mapSize, width: mapSize)
        mapView.layer.cornerRadius = mapSize/2
        mapView.centerX(inView: circularProgressView)
        mapView.centerY(inView: circularProgressView, constant: 32)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: circularProgressView.bottomAnchor, paddingTop: 32)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                                paddingTop: 16, paddingLeft: 32, paddingRight: 32, height: 50)
    }
    
    private func startTimer () {
      guard timer == nil else { return }

        timer = Timer.scheduledTimer(
          timeInterval: 1,
          target: self,
          selector: #selector(updateTime),
          userInfo: nil,
          repeats: true)
    }
    
    private func resetTimer() {
        timer?.invalidate()
        totalSeconds = 0
        timer = nil
    }
    
    // MARK: - Actions
    @objc private func didTapCancelButton() {
        dismiss(animated: true) {
            self.resetTimer()
            DriverService.shared.updateTripState(trip: self.trip, state: .denied) { err, ref in
                
            }
            print("didTapCancelButton")
        }
    }
    
    @objc private func animateProgress() {
        circularProgressView.animatePulsatingLayer()
        startTimer()
        circularProgressView.setProgressWithAnimation(duration: 7, value: 0) {
            
        }
    }
    
    @objc private func updateTime()  {
        totalSeconds += 1
        if timer != nil, totalSeconds > 7 {
            didTapCancelButton()
        }
    }
    
    @objc private func didTapAcceptButton() {
        resetTimer()
        DriverService.shared.acceptTrip(trip: trip) { error, ref in
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
}
