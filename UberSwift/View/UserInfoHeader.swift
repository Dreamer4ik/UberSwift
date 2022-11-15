//
//  UserInfoHeader.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 05.11.2022.
//

import UIKit

class UserInfoHeader: UIView {
    // MARK: - Properties
    private let user: User
    
    private let profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let initialLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textColor = .lightGray
        return label
    }()
    
    // MARK: - Lifecycle
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        backgroundColor = .white
        configureLabels(user: user)
        
        addSubview(profileImageView)
        let profileImageSize: CGFloat = 64
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        profileImageView.setDimensions(height: profileImageSize, width: profileImageSize)
        profileImageView.layer.cornerRadius = profileImageSize/2
        
        addSubview(initialLabel)
        initialLabel.centerX(inView: profileImageView)
        initialLabel.centerY(inView: profileImageView)
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        
        addSubview(stack)
        stack.centerY(inView: profileImageView,
                      leftAnchor: profileImageView.rightAnchor,
                      paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    private func configureLabels(user: User) {
        fullnameLabel.text = user.fullname
        emailLabel.text = user.email
        initialLabel.text = user.firstInitial
    }
}
