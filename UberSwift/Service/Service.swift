//
//  Service.swift
//  UberSwift
//
//  Created by Ivan Potapenko on 18.10.2022.
//

import Firebase

// MARK: - DatabaseRefs
let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

final class Service {
    public static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(completion: @escaping (User) -> Void) {
        guard let currentUid = currentUid else {
            return
        }
        REF_USERS.child(currentUid).observe(.value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            let user = User(dictionary: dictionary)
            completion(user)
        }
    }
}
