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
    private let blackView = UIView()
    
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
        checkIfUserIsLoggedIn()
        NotificationCenter.default.addObserver(self, selector: #selector(config), name: NSNotification.Name(rawValue: "AuthFetchData"), object: nil)
    }
    
    override var prefersStatusBarHidden: Bool  {
        return isExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    // MARK: - Shared API
    
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            presentLoginController()
        }  else {
            config()
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
        menuController.delegate = self
        configureBlackView()
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
    
    @objc private func config() {
        view.backgroundColor = .backgroundColor
        configureHomeController()
        fetchUserData()
    }
    
    private func configureBlackView() {
        blackView.frame = view.bounds
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        view.addSubview(blackView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    private func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
        let xOrigin = view.frame.width - 80
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = xOrigin
                self.blackView.alpha = 1
                self.blackView.frame = CGRect(
                    x: xOrigin,
                    y: 0,
                    width: 80,
                    height: self.view.height
                )
            }, completion: nil)
        } else {
            self.blackView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
            }, completion: completion)
        }
        animateStatusBar()
    }
    
    private func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    // MARK: - Actions
    @objc private func dismissMenu() {
        isExpanded = false
        animateMenu(shouldExpand: isExpanded)
    }
}

// MARK: - HomeViewControllerDelegate
extension ContainerViewController: HomeViewControllerDelegate{
    func didTapShowMenu() {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}

// MARK: - MenuViewControllerDelegate
extension ContainerViewController: MenuViewControllerDelegate {
    func didSelect(option: MenuOptions) {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded) { _ in
            switch option {
            case .yourTrips:
                break
            case .settings:
                break
            case .logout:
                let alert = UIAlertController(title: nil,
                                              message: "Are you sure you want to log out?",
                                              preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                    self.signOut()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
            }
        }
    }
}
