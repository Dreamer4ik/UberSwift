//
//  SettingsViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 05.11.2022.
//

import UIKit

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home:
            return "Home"
        case .work:
            return "Work"
        }
    }
    
    var subTitle: String {
        switch self {
        case .home:
            return "Add Home"
        case .work:
            return "Add Work"
        }
    }
}

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    static let identifier = "SettingsViewController"
    private let user: User
    
    private let tablewView: UITableView = {
        let table = UITableView()
        table.register(LocationTableViewCell.self, forCellReuseIdentifier: LocationTableViewCell.identifier)
        table.register(LocationTableHeader.self, forHeaderFooterViewReuseIdentifier: LocationTableHeader.identifier)
        return table
    }()
    
    private var infoHeader: UserInfoHeader?
    
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
        view.backgroundColor = .magenta
        configureTableView()
        configureNavigationBar()
    }
    
    // MARK: - Helpers
    private func configureTableView() {
        view.addSubview(tablewView)
        tablewView.delegate = self
        tablewView.dataSource = self
        tablewView.backgroundColor = .white
        tablewView.frame = view.bounds
        let frame = CGRect(
            x: 0,
            y: 0,
            width: view.width,
            height: 100)
        infoHeader = UserInfoHeader(user: user, frame: frame)
        tablewView.tableHeaderView = infoHeader
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        let barAppearance = UINavigationBarAppearance()
        barAppearance.backgroundColor = .backgroundColor
//        barAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//        barAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        
        navigationItem.title = "Settings"
        let image = UIImage(named: "baseline_clear_white_36pt_2x")?.withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didTapCancel))
    }
    // MARK: - Actions
    @objc private func didTapCancel() {
        self.dismiss(animated: true)
    }
    
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: LocationTableHeader.identifier) as? LocationTableHeader else {
            return UIView()
        }
        
        if section == 0 {
            header.configure(with: "Favorites", backgroundColor: .backgroundColor, labelColor: .white)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LocationTableViewCell.identifier,
            for: indexPath
        ) as? LocationTableViewCell else {
            preconditionFailure("LocationTableViewCell error")
        }
        
        guard let type = LocationType(rawValue: indexPath.row) else {
            preconditionFailure("LocationType error")
        }
        cell.configureLabel(type: type)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let type = LocationType(rawValue: indexPath.row) else {
            return
        }
        print("Type is \(type.description)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
