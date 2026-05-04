import Foundation

struct AdviceLog: Identifiable {
    var id: String = ""
    var docId: String = ""
    var createdAtRaw: String = ""
    var level: String = ""
    var levelEnum: AdviceLogLevel = .other
    var message: String = ""
    var cityCategory: String = ""
    var serverName: String = ""
    var error: String = ""
    var occurredAt: String = ""
    var scheduleId: String = ""
    var applicationName: String = ""
}
