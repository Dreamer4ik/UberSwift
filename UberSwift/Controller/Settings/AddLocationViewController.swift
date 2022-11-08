//
//  AddLocationViewController.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 07.11.2022.
//

import UIKit
import MapKit

protocol AddLocationViewControllerDelegate: AnyObject {
    func updateLocation(locationString: String, type: LocationType)
}

class AddLocationViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let searchBar = UISearchBar()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]() {
        didSet {
            tableView.reloadData()
        }
    }
    private let type: LocationType
    private let location: CLLocation
    weak var delegate: AddLocationViewControllerDelegate?
    
    // MARK: - Lifecycle
    
    init(type: LocationType, location: CLLocation) {
        self.type = type
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureSearchBar()
        configureSearchCompeleter()
        
        print("Type is \(type.description)")
        print("Location is \(location)")
    }
    
    // MARK: - Helpers
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.addShadow()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
    }
    
    private func configureSearchBar() {
        searchBar.backgroundColor = .backgroundColor
        searchBar.searchTextField.backgroundColor = .white
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }
    
    private func configureSearchCompeleter() {
        let region = MKCoordinateRegion(center: location.coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        searchCompleter.region = region
        searchCompleter.delegate = self
    }
    
    // MARK: - Actions
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AddLocationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let result = searchResults[indexPath.row]
        if #available(iOS 14.0, *) {
            var config = cell.defaultContentConfiguration()
            config.text = result.title
            config.secondaryText = result.subtitle
            cell.contentConfiguration = config
        } else {
            cell.textLabel?.text = result.title
            cell.detailTextLabel?.text = result.subtitle
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let title = result.title
        let subtitle = result.subtitle
        let locationString = title + " " + subtitle
        let trimmedLocation = locationString.replacingOccurrences(of: ", United States", with: "")
        delegate?.updateLocation(locationString: trimmedLocation, type: type)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension AddLocationViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
        
        if let searchTextField = self.searchBar.value(forKey: "searchField") as? UITextField , let clearButton = searchTextField.value(forKey: "_clearButton")as? UIButton {
            
            clearButton.addTarget(self, action: #selector(cleanField), for: .touchUpInside)
        }
    }
    
    @objc private func cleanField() {
        searchBar.text = ""
        searchResults.removeAll()
        tableView.reloadData()
        searchBar.endEditing(true)
    }
    
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddLocationViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}

