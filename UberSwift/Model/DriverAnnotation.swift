//
//  DriverAnnotation.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 19.10.2022.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    static let identifier = "DriverAnnotation"
    
    dynamic var coordinate: CLLocationCoordinate2D
    var uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationPosition(withCoordinate coordinate: CLLocationCoordinate2D) {
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            self.coordinate = coordinate
        }
        animator.startAnimation()
    }
    
}
