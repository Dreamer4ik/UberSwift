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

// MARK: - DriverService
final class DriverService {
    static let shared = DriverService()
    let currentUid = Auth.auth().currentUser?.uid
    
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
    
    func observeTripCancelled(trip: Trip, completion: @escaping () -> Void) {
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
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
    
    func updateTripState(trip: Trip, state: TripState, completion: @escaping(Error?, DatabaseReference) -> Void) {
        REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        
        if state == .completed {
            REF_TRIPS.child(trip.passengerUid).removeAllObservers()
        }
    }
    
    func updateDriverLocation(location: CLLocation) {
        guard let currentUid = currentUid else {
            return
        }
        let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geoFire.setLocation(location, forKey: currentUid)
    }
}

// MARK: - PassengerService
final class PassengerService {
    static let shared = PassengerService()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchDrivers(location: CLLocation, completion: @escaping (User) -> Void) {
        let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        REF_DRIVER_LOCATIONS.observe(.value) { snapshot in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                Service.shared.fetchUserData(uid: uid) { user in
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
    
    func deleteTrip(completion: @escaping (Error?, DatabaseReference) -> Void) {
        guard let currentUid = currentUid else {
            return
        }
        
        REF_TRIPS.child(currentUid).removeValue(completionBlock: completion)
    }
    
    func saveLocation(
        locationString: String,
        type: LocationType,
        completion: @escaping (Error?, DatabaseReference) -> Void
    ) {
        guard let currentUid = currentUid else {
            return
        }
        let key: String = type == .home ? "homeLocation" : "workLocation"
        REF_USERS.child(currentUid).child(key).setValue(locationString, withCompletionBlock: completion)
    }
}

// MARK: - Shared Service
final class Service {
    static let shared = Service()
    
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
}
