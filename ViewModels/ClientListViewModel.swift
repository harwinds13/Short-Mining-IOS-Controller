import Foundation
import FirebaseFirestore

@Observable
final class ClientListViewModel {
    var clients: [Client] = []
    var filteredClients: [Client] = []
    var searchQuery: String = "" {
        didSet { applySearchAndFilter() }
    }
    var selectedFilter: String = "All" {
        didSet { applySearchAndFilter() }
    }
    var isLoading: Bool = false
    var hasFormAccess: Bool = false

    // Status counts
    var finishedCount: Int = 0
    var errorCount: Int = 0
    var processingCount: Int = 0
    var otherCount: Int = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Fetch clients with real-time listener
    func fetchClients(
        company: String,
        subCompanies: [String],
        collectionName: String,
        vendorFilter: String? = nil
    ) {
        isLoading = true
        listener?.remove()

        var query: Query = db.collection(collectionName)

        if let vendorFilter = vendorFilter {
            query = query.whereField("vendor", isEqualTo: vendorFilter)
        } else {
            // Exclude DUMMY vendor from normal lists
            let vendors = subCompanies.filter { $0 != "DUMMY" }
            if !vendors.isEmpty {
                query = query.whereField("vendor", in: vendors)
            }
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            self.isLoading = false
            guard let snapshot, error == nil else { return }

            self.clients = snapshot.documents.compactMap { doc -> Client? in
                let data = doc.data()
                var client = Client()
                client.id = doc.documentID
                client.bbCandidateId = data["bbCandidateId"] as? String ?? doc.documentID
                client.expireTime = data["expireTime"] as? Int64 ?? (data["expireTime"] as? Int ?? 0).int64
                client.jobType = data["jobType"] as? String ?? ""
                client.location = data["location"] as? String ?? ""
                client.status = data["status"] as? String ?? ""
                client.clientName = data["clientName"] as? String ?? ""
                client.clientPhoneNumber = data["clientPhoneNumber"] as? String ?? ""
                client.clientEmail = data["clientEmail"] as? String ?? ""
                client.error = data["error"] as? String ?? ""
                client.pod = data["pod"] as? String ?? ""
                client.job = data["job"] as? String ?? ""
                client.sch = data["sch"] as? String ?? ""
                client.applicationId = data["applicationId"] as? String ?? ""
                client.vendor = data["vendor"] as? String ?? ""
                client.loginPin = data["loginPin"] as? String ?? ""
                client.fullLocal = data["fullLocal"] as? [String: String] ?? [:]
                client.autoLoginAttempt = data["autoLoginAttempt"] as? String ?? ""
                client.passKey = data["passKey"] as? String ?? ""
                client.pin = data["pin"] as? String ?? ""
                client.accessToken = data["accessToken"] as? String ?? ""
                return client
            }
            .sorted { lhs, rhs in
                let lhsFinal = Self.isFinalSuccess(lhs.status)
                let rhsFinal = Self.isFinalSuccess(rhs.status)
                if lhsFinal != rhsFinal { return lhsFinal }
                return lhs.expireTime > rhs.expireTime
            }

            self.updateStatusCounts()
            self.applySearchAndFilter()
        }
    }

    // MARK: - Apply filter
    func applyFilter(_ filter: String) {
        selectedFilter = filter
    }

    // MARK: - Apply search and filter together
    private func applySearchAndFilter() {
        var result = clients

        if selectedFilter != "All" {
            result = result.filter { $0.status == selectedFilter }
        }

        let q = searchQuery.lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.clientName.lowercased().contains(q)
                || $0.bbCandidateId.lowercased().contains(q)
                || $0.clientEmail.lowercased().contains(q)
                || $0.clientPhoneNumber.lowercased().contains(q)
                || $0.status.lowercased().contains(q)
            }
        }

        filteredClients = result
    }

    // MARK: - Update status counts
    private func updateStatusCounts() {
        finishedCount = clients.filter { Self.isFinalSuccess($0.status) }.count
        errorCount = clients.filter { Self.isError($0.status) }.count
        processingCount = clients.filter { $0.status == "submitted" }.count
        otherCount = clients.filter { $0.status == "locked" }.count
    }

    static func isFinalSuccess(_ status: String) -> Bool {
        ["FINAL_SUCCESS", "contingent-offer-completed", "job-opportunities-completed", "general-questions-completed"].contains(status)
    }

    static func isError(_ status: String) -> Bool {
        ["token_expired", "system_interrupt", "generic_error"].contains(status)
    }

    deinit {
        listener?.remove()
    }
}

private extension Int {
    var int64: Int64 { Int64(self) }
}
