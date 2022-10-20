//
//  LocationTableViewCell.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 17.10.2022.
//

import UIKit
import MapKit

class LocationTableViewCell: UITableViewCell {
    // MARK: - Properties
    static let identifier = "LocationTableViewCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        addSubview(stack)
        stack.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func prepareForReuse() {
        titleLabel.text = nil
        addressLabel.text = nil
    }
    
    func configureLabel(placemark: MKPlacemark) {
        titleLabel.text = placemark.name
        addressLabel.text = placemark.address
    }
    
}
