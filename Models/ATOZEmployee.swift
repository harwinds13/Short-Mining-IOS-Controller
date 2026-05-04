import Foundation

struct ATOZEmployee: Identifiable {
    var id: String = ""
    var docId: String = ""
    var employeeId: String = ""
    var isFullShiftPreferInPriorDay: Bool = false
    var isHalfShiftPreferInPriorDay: Bool = false
    var isShiftTypeVet: Bool = false
    var name: String = ""
    var priorityDays: [String] = []
    var priorityOrder: [String] = []
    var refreshSessionExpiration: Int64 = 0
    var siteID: String = ""
    var status: String = ""
    var server: String = ""
    var cookie: String? = nil
    var lastUpdated: String = ""
    var latestHours: Double = 0.0
}
