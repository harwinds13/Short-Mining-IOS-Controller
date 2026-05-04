import Foundation
import FirebaseAuth
import FirebaseFirestore
import AudioToolbox

@Observable
final class PortalViewModel {
    var vendorName: String = ""
    var vendorEmail: String = ""
    var vendorPhone: String = ""
    var vendorCompany: String = ""
    var company: String = ""
    var subCompanies: [String] = []
    var hasPermissionToClearLog: Bool = false
    var hasAtozAccess: Bool = false
    var hasServiceLogsAccess: Bool = false
    var hasFormAccess: Bool = false
    var logs: [AdviceLog] = []
    var hasNewInfoLog: Bool = false

    private let db = Firestore.firestore()
    private var logsListener: ListenerRegistration?
    private var isInitialLoad = true

    // MARK: - Load vendor profile
    func loadVendorProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self, let data = snapshot?.data(), error == nil else { return }
            self.vendorName = data["name"] as? String ?? ""
            self.vendorEmail = data["email"] as? String ?? ""
            self.vendorPhone = data["phone"] as? String ?? ""
            self.company = data["company"] as? String ?? ""
            self.vendorCompany = self.company
            self.hasPermissionToClearLog = data["has_permission_to_clear_log"] as? Bool ?? false
            self.hasAtozAccess = data["has_atoz_access"] as? Bool ?? false
            self.hasServiceLogsAccess = data["has_service_logs_access"] as? Bool ?? false
            self.hasFormAccess = data["has_form_access"] as? Bool ?? false

            if self.company == "Admin" {
                self.subCompanies = data["sub_companies"] as? [String] ?? ["LADDI", "DILMAN", "SKY_ATOZ", "HARGUN", "SHORT_MINING", "MANI"]
            } else {
                self.subCompanies = [self.company]
            }
        }
    }

    // MARK: - Setup logs listener
    func setupLogsListener() {
        isInitialLoad = true
        logsListener?.remove()
        logsListener = db.collection("service_logs")
            .order(by: "occurredAt", descending: true)
            .limit(to: 200)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot, error == nil else { return }

                var newLogs: [AdviceLog] = []
                var foundNewInfo = false

                for diff in snapshot.documentChanges {
                    if diff.type == .added && !self.isInitialLoad {
                        let data = diff.document.data()
                        let levelStr = (data["level"] as? String ?? "").uppercased()
                        if levelStr == "INFO" {
                            foundNewInfo = true
                        }
                    }
                }

                newLogs = snapshot.documents.compactMap { doc -> AdviceLog? in
                    let data = doc.data()
                    let levelStr = (data["level"] as? String ?? "").uppercased()
                    var log = AdviceLog()
                    log.id = doc.documentID
                    log.docId = doc.documentID
                    log.level = levelStr
                    log.levelEnum = Self.parseLevel(levelStr)
                    log.message = data["message"] as? String ?? ""
                    log.cityCategory = data["cityCategory"] as? String ?? ""
                    log.serverName = data["serverName"] as? String ?? ""
                    log.error = data["error"] as? String ?? ""
                    log.occurredAt = data["occurredAt"] as? String ?? ""
                    log.scheduleId = data["scheduleId"] as? String ?? ""
                    log.applicationName = data["applicationName"] as? String ?? ""
                    log.createdAtRaw = data["createdAt"] as? String ?? ""
                    return log
                }

                self.logs = newLogs
                self.isInitialLoad = false

                if foundNewInfo {
                    self.hasNewInfoLog = true
                    AudioServicesPlaySystemSound(1315)
                }
            }
    }

    // MARK: - Clear all logs in batches of 450
    func clearAllLogs() {
        db.collection("service_logs").getDocuments { [weak self] snapshot, error in
            guard let self, let docs = snapshot?.documents, error == nil else { return }
            let chunks = stride(from: 0, to: docs.count, by: 450).map {
                Array(docs[$0..<min($0 + 450, docs.count)])
            }
            for chunk in chunks {
                let batch = self.db.batch()
                chunk.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in }
            }
        }
    }

    func getSubCompaniesForIntent() -> [String] {
        return subCompanies
    }

    static func parseLevel(_ raw: String) -> AdviceLogLevel {
        switch raw {
        case "INFO": return .info
        case "ERROR": return .error
        case "WARNING": return .warning
        default: return .other
        }
    }

    deinit {
        logsListener?.remove()
    }
}
