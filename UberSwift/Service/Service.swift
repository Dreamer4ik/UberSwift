//
//  Service.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 18.10.2022.
//

import Firebase
import GeoFire

// MARK: - DatabaseRefs
let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")

final class Service {
    public static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(uid: String, completion: @escaping (User) -> Void) {
        REF_USERS.child(uid).observe(.value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
    
    func fetchDrivers(location: CLLocation, completion: @escaping (User) -> Void) {
        let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        REF_DRIVER_LOCATIONS.observe(.value) { snapshot in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                self.fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
    
    func uploadTrip(
        pickupCoordinates: CLLocationCoordinate2D,
        destinationCoordinates: CLLocationCoordinate2D,
        completion: @escaping (Error?, DatabaseReference) -> Void
    ) {
        guard let uid = currentUid else {
            return
        }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = [
            "pickupCoordinates": pickupArray,
            "destinationCoordinates": destinationArray,
            "state": TripState.requested.rawValue
        ] as [String : Any]
        
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeTrips(completion: @escaping (Trip) -> Void) {
        REF_TRIPS.observe(.childAdded) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping (Error?, DatabaseReference) -> Void) {
        guard let currentUid = currentUid else {
            return
        }
        let values = [
            "driverUid": currentUid,
            "state": TripState.accepted.rawValue
        ] as [String : Any]
        
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeCurrentTrip(completion: @escaping (Trip) -> Void) {
        guard let currentUid = currentUid else {
            return
        }
        
        REF_TRIPS.child(currentUid).observe(.value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
}
