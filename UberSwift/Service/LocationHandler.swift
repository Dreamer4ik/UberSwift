//
//  LocationHandler.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 18.10.2022.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    public static let shared = LocationHandler()
    var locationManager: CLLocationManager?
    var location: CLLocation?
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            locationManager?.requestAlwaysAuthorization()
        }
    }
}
