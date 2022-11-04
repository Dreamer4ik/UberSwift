//
//  MenuViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 02.11.2022.
//

import UIKit

enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrips
    case settings
    case logout
    
    var description: String {
        switch self {
        case .yourTrips:
            return "Your trips"
        case .settings:
            return "Settings"
        case .logout:
            return "Log Out"
        }
    }
}

protocol MenuViewControllerDelegate: AnyObject {
    func didSelect(option: MenuOptions)
}

class MenuViewController: UIViewController {
    
    // MARK: - Properties
    
    private let user: User
    weak var delegate: MenuViewControllerDelegate?
    
    private let tablewView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private var headerView: MenuHeader?
    
    // MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tablewView.frame = view.bounds
        
    }
    
    // MARK: - Helpers
    private func configureTableView() {
        view.addSubview(tablewView)
        tablewView.delegate = self
        tablewView.dataSource = self
        tablewView.separatorStyle = .none
        tablewView.isScrollEnabled = false
        
        let frame = CGRect(
            x: 0,
            y: 0,
            width: view.width,
            height: 200)
        headerView = MenuHeader(user: user, frame: frame)
        tablewView.tableHeaderView = headerView
    }
    
    // MARK: - Actions
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuOptions.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let option = MenuOptions(rawValue: indexPath.row) else { preconditionFailure("MenuOptions error") }
        if #available(iOS 14.0, *) {
            var config = cell.defaultContentConfiguration()
            config.text = option.description
            cell.contentConfiguration = config
        } else {
            cell.textLabel?.text = option.description
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let option = MenuOptions(rawValue: indexPath.row) else { return }
        delegate?.didSelect(option: option)
    }
}
