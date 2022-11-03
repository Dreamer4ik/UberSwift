//
//  MenuHeader.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 03.11.2022.
//

import UIKit

class MenuHeader: UIView {
    // MARK: - Properties
    private let user: User
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.text = "iOS Dev"
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textColor = .lightGray
        label.text = "apple@gmail.com"
        return label
    }()
    
    // MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        backgroundColor = .backgroundColor
        configureLabels(user: user)
        
        addSubview(profileImageView)
        let profileImageSize: CGFloat = 64
        
        
        let height = UIApplication.shared.statusBarHeight
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: height,
                                paddingLeft: 12, width: profileImageSize, height: profileImageSize)
        profileImageView.layer.cornerRadius = profileImageSize/2
        
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
    }
    
    // MARK: - Actions
}

extension UIApplication {
    var statusBarHeight: CGFloat {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .compactMap {
                $0.statusBarManager
            }
            .map {
                $0.statusBarFrame
            }
            .map(\.height)
            .max() ?? 0
    }
}
