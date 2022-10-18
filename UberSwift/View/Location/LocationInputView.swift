//
//  LocationInputView.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 17.10.2022.
//

import UIKit

protocol LocationInputViewDelegate: AnyObject {
    func dismissLocationInputView()
}

class LocationInputView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: LocationInputViewDelegate?
    
    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "baseline_arrow_back_black_36dp")?.withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let startLocationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let linkingView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        return view
    }()
    
    private let destinationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let startLocationTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Current Location"
        field.backgroundColor = .systemGroupedBackground
        field.isEnabled = false
        field.font = .systemFont(ofSize: 14)
        
        let padding = UIView()
        padding.setDimensions(height: 30, width: 8)
        field.leftView = padding
        field.leftViewMode = .always
        
        return field
    }()
    
    private let destinationLocationTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter a destination..."
        field.backgroundColor = UIColor.rgb(red: 215, green: 215, blue: 215)
        field.returnKeyType = .search
        field.font = .systemFont(ofSize: 14)
        
        let padding = UIView()
        padding.setDimensions(height: 30, width: 8)
        field.leftView = padding
        field.leftViewMode = .always
        
        return field
    }()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        addShadow()
        
        addSubview(backButton)
        backButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 44,
                          paddingLeft: 12, width: 24, height: 24)
        
        addSubview(titleLabel)
        titleLabel.centerY(inView: backButton)
        titleLabel.centerX(inView: self)
        
        addSubview(startLocationTextField)
        startLocationTextField.anchor(top: backButton.bottomAnchor, left: leftAnchor, right: rightAnchor,
                                      paddingTop: 4, paddingLeft: 40, paddingRight: 40, height: 30)
        
        addSubview(destinationLocationTextField)
        destinationLocationTextField.anchor(top: startLocationTextField.bottomAnchor, left: leftAnchor, right: rightAnchor,
                                            paddingTop: 12, paddingLeft: 40, paddingRight: 40, height: 30)
        
        addSubview(startLocationIndicatorView)
        startLocationIndicatorView.centerY(inView: startLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
        let sizeIndicator: CGFloat = 6
        startLocationIndicatorView.setDimensions(height: sizeIndicator, width: sizeIndicator)
        startLocationIndicatorView.layer.cornerRadius = sizeIndicator/2
        
        addSubview(destinationIndicatorView)
        destinationIndicatorView.centerY(inView: destinationLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
        destinationIndicatorView.setDimensions(height: sizeIndicator, width: sizeIndicator)
        
        addSubview(linkingView)
        linkingView.centerX(inView: startLocationIndicatorView)
        linkingView.anchor(top: startLocationIndicatorView.bottomAnchor, bottom: destinationIndicatorView.topAnchor,
                           paddingTop: 4, paddingBottom: 4, width: 0.5)
        
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    func configureTitle(text: String) {
        titleLabel.text = text
    }
    
    // MARK: - Actions
    @objc private func didTapBack() {
        delegate?.dismissLocationInputView()
    }
}
