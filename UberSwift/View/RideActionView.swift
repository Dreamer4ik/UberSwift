//
//  RideActionView.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 22.10.2022.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: AnyObject {
    func uploadTrip(_ view: RideActionView)
}

enum RideActionViewConfiguration {
    case requestRide
    case tripAccepted
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide:
            return "CONFIRM UBERX"
        case .cancel:
            return "CANCEL RIDE"
        case .getDirections:
            return "GET DIRECTIONS"
        case .pickup:
            return "PICKUP PASSENGER"
        case .dropOff:
            return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

class RideActionView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: RideActionViewDelegate?
    var config = RideActionViewConfiguration()
    var buttonAction = ButtonAction()
    var destination: MKPlacemark?
    var user: User?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let adressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
//        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let infoViewLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        label.textColor = .white
        label.text = "X"
        return label
    }()
    
    private let uberInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.text = "UberX"
        label.textAlignment = .center
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, adressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        let infoSize: CGFloat = 60
        infoView.setDimensions(height: infoSize, width: infoSize)
        infoView.layer.cornerRadius = infoSize/2
        
        
        infoView.addSubview(infoViewLabel)
        infoViewLabel.centerX(inView: infoView)
        infoViewLabel.centerY(inView: infoView)
        
        addSubview(uberInfoLabel)
        uberInfoLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        uberInfoLabel.centerX(inView: self)
        
        addSubview(separatorView)
        separatorView.anchor(top: uberInfoLabel.bottomAnchor, left: leftAnchor, right: rightAnchor,
                             paddingTop: 4, height: 0.75)
        
        
        addSubview(actionButton)
        actionButton.anchor(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor,
                            paddingLeft: 12, paddingBottom: 12, paddingRight: 12, height: 50)
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func didTapActionButton() {
        switch buttonAction {
        case .requestRide:
            delegate?.uploadTrip(self)
        case .cancel:
            print("cancel")
        case .getDirections:
            print("getDirections")
        case .pickup:
            print("pickup")
        case .dropOff:
            print("dropOff")
        }
    }
    
    func configureLabel(placemark: MKPlacemark) {
        titleLabel.text = placemark.name
        let attributedText = NSMutableAttributedString(string: "\("Adress:")",
                                                       attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold)])
        
        attributedText.append(NSAttributedString(string: "  \(placemark.address ?? "")",
                                                 attributes: [.font: UIFont.systemFont(ofSize: 16)]))
        adressLabel.attributedText = attributedText
        destination = placemark
    }
    
    // MARK: - Helper Functions
    func configureUI(withConfig config: RideActionViewConfiguration) {
        switch config {
        case .requestRide:
            buttonAction = .requestRide
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .tripAccepted:
            guard let user = user else {
                return
            }
            
            if user.accountType == .passenger {
                titleLabel.text = "En Route To Passenger"
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            else {
                buttonAction = .cancel
                actionButton.setTitle(buttonAction.description, for: .normal)
                titleLabel.text = "Driver En Route"
            }
            
            infoViewLabel.text = String(user.fullname.first ?? "X")
            uberInfoLabel.text = user.fullname
            
        case .pickupPassenger:
            titleLabel.text = "Arrived to passenger Location"
            buttonAction = .pickup
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .tripInProgress:
            guard let user = user else {
                return
            }
            
            if user.accountType == .driver {
                actionButton.setTitle("TRIP IN PROGRESS", for: .normal)
                actionButton.isEnabled = false
            }
            else {
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            titleLabel.text = "En Route to destination"
        case .endTrip:
            guard let user = user else {
                return
            }
            
            if user.accountType == .driver {
                actionButton.setTitle("ARRIVED TO DESTINATION", for: .normal)
                actionButton.isEnabled = false
            }
            else {
                buttonAction = .dropOff
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
        }
    }
}
