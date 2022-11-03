//
//  ContainerViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 02.11.2022.
//

import UIKit
import Firebase

class ContainerViewController: UIViewController {
    
    // MARK: - Properties
    private let homeController = HomeViewController()
    private var menuController: MenuViewController!
    private var isExpanded = false
    
    private var user: User? {
        didSet {
            guard let user = user else {
                return
            }
            homeController.user = user
            configureMenuController(withUser: user)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        configureHomeController()
        fetchUserData()
    }
    
    // MARK: - Shared API
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    // MARK: - Helpers
    private func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
        homeController.user = user
    }
    
    private func configureMenuController(withUser user: User) {
        menuController = MenuViewController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
    }
    
    // FixME
//    func configure() {
//        view.backgroundColor = .backgroundColor
//        fetchUserData()
//    }
    
    private func animateMenu(shouldExpand: Bool) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.view.frame.width - 80
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
            }, completion: nil)
        }
    }
    // MARK: - Actions
}

extension ContainerViewController: HomeViewControllerDelegate{
    func didTapShowMenu() {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}
