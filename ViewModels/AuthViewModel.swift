import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AuthViewModel {
    var isLoggedIn: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private var statusListener: ListenerRegistration?
    private let db = Firestore.firestore()

    // MARK: - Login
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            guard let uid = result?.user.uid else {
                self.errorMessage = "Unknown error during login."
                self.isLoading = false
                return
            }
            self.db.collection("users").document(uid).getDocument { snapshot, error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    try? Auth.auth().signOut()
                    return
                }
                let status = snapshot?.data()?["status"] as? String ?? ""
                if status == "active" {
                    self.isLoggedIn = true
                    self.startStatusListener(userId: uid)
                } else {
                    self.errorMessage = "Account not yet activated. Please contact admin."
                    try? Auth.auth().signOut()
                }
            }
        }
    }

    // MARK: - Register
    func register(name: String, email: String, password: String, phone: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(error)
                return
            }
            guard let uid = result?.user.uid else {
                self.isLoading = false
                completion(nil)
                return
            }
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "phone": phone,
                "status": "inactive",
                "has_form_access": false,
                "has_atoz_access": false,
                "has_service_logs_access": false,
                "has_permission_to_clear_log": false
            ]
            self.db.collection("users").document(uid).setData(userData) { writeError in
                self.isLoading = false
                if let writeError = writeError {
                    self.errorMessage = writeError.localizedDescription
                    completion(writeError)
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Sign out
    func signOut() {
        statusListener?.remove()
        statusListener = nil
        try? Auth.auth().signOut()
        isLoggedIn = false
    }

    // MARK: - Real-time status listener
    func startStatusListener(userId: String) {
        statusListener?.remove()
        statusListener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            let status = snapshot?.data()?["status"] as? String ?? ""
            if status != "active" {
                self.signOut()
            }
        }
    }
}
