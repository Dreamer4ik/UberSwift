//
//  LocationTableHeader.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 17.10.2022.
//

import UIKit

class LocationTableHeader: UITableViewHeaderFooterView {
    static let identifier = "LocationTableHeader"
    
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 10, y: 0, width: width-30, height: height)
    }
    
    func configure(with title: String) {
        label.text = title
    }
}
