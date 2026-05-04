import Foundation
import FirebaseFirestore

@Observable
final class ATOZViewModel {
    var employees: [ATOZEmployee] = []
    var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Fetch employees with real-time listener
    func fetchEmployees() {
        isLoading = true
        listener?.remove()
        listener = db.collection("atoz").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            self.isLoading = false
            guard let snapshot, error == nil else { return }

            self.employees = snapshot.documents.compactMap { doc -> ATOZEmployee? in
                let data = doc.data()
                var emp = ATOZEmployee()
                emp.id = doc.documentID
                emp.docId = doc.documentID
                emp.employeeId = data["employeeId"] as? String ?? ""
                emp.isFullShiftPreferInPriorDay = data["isFullShiftPreferInPriorDay"] as? Bool ?? false
                emp.isHalfShiftPreferInPriorDay = data["isHalfShiftPreferInPriorDay"] as? Bool ?? false
                emp.isShiftTypeVet = data["isShiftTypeVet"] as? Bool ?? false
                emp.name = data["name"] as? String ?? ""
                emp.priorityDays = data["priorityDays"] as? [String] ?? []
                emp.priorityOrder = data["priorityOrder"] as? [String] ?? []
                emp.refreshSessionExpiration = data["refreshSessionExpiration"] as? Int64 ?? 0
                emp.siteID = data["siteID"] as? String ?? ""
                emp.status = data["status"] as? String ?? ""
                emp.server = data["server"] as? String ?? ""
                emp.cookie = data["cookie"] as? String
                emp.lastUpdated = data["lastUpdated"] as? String ?? ""
                emp.latestHours = data["latestHours"] as? Double ?? 0.0
                return emp
            }
            .sorted { lhs, rhs in
                let order = ["ONLINE": 0, "ACTIVE": 1]
                let lhsO = order[lhs.status] ?? 2
                let rhsO = order[rhs.status] ?? 2
                if lhsO != rhsO { return lhsO < rhsO }
                return lhs.name < rhs.name
            }
        }
    }

    // MARK: - Save employee
    func saveEmployee(emp: ATOZEmployee, updates: [String: Any]) {
        db.collection("atoz").document(emp.docId).updateData(updates) { error in
            if let error = error {
                print("ATOZViewModel.saveEmployee error: \(error)")
            }
        }
    }

    // MARK: - Logout employee (cookie=nil, status=OFFLINE)
    func logoutEmployee(emp: ATOZEmployee) {
        db.collection("atoz").document(emp.docId).updateData([
            "cookie": NSNull(),
            "status": "OFFLINE"
        ]) { error in
            if let error = error {
                print("ATOZViewModel.logoutEmployee error: \(error)")
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
