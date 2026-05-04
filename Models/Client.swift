import Foundation

struct Client: Identifiable, Codable {
    var id: String = ""
    var bbCandidateId: String = ""
    var expireTime: Int64 = 0
    var jobType: String = ""
    var location: String = ""
    var status: String = ""
    var clientName: String = ""
    var clientPhoneNumber: String = ""
    var clientEmail: String = ""
    var error: String = ""
    var pod: String = ""
    var job: String = ""
    var sch: String = ""
    var applicationId: String = ""
    var vendor: String = ""
    var loginPin: String = ""
    var fullLocal: [String: String] = [:]
    var autoLoginAttempt: String = ""
    var passKey: String = ""
    var pin: String = ""
    var accessToken: String = ""
}
