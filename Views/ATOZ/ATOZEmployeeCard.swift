import SwiftUI

struct ATOZEmployeeCard: View {
    let employee: ATOZEmployee
    let onTap: () -> Void

    private static let expiryFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(employee.employeeId.isEmpty ? "—" : employee.employeeId)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                statusBadge
            }

            Text(employee.name.isEmpty ? "—" : employee.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            if !employee.siteID.isEmpty {
                Text("Site: \(employee.siteID)")
                    .font(.caption)
            }

            if !employee.server.isEmpty {
                Text("Server: \(employee.server)")
                    .font(.caption)
                    .lineLimit(1)
            }

            if employee.latestHours > 0 {
                Text(String(format: "Hours: %.1f", employee.latestHours))
                    .font(.caption)
            }

            if !employee.lastUpdated.isEmpty {
                Text("Updated: \(employee.lastUpdated)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if employee.refreshSessionExpiration > 0 {
                let expDate = Date(timeIntervalSince1970: Double(employee.refreshSessionExpiration) / 1000)
                Text("Session: \(Self.expiryFormatter.localizedString(for: expDate, relativeTo: Date()))")
                    .font(.caption2)
                    .foregroundStyle(expDate < Date() ? .red : .secondary)
            }
        }
        .padding(10)
        .background(cardBackground)
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }

    private var statusBadge: some View {
        Text(employee.status.isEmpty ? "OFFLINE" : employee.status)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch employee.status {
        case "ONLINE": return .green
        case "ACTIVE": return .blue
        default: return .gray
        }
    }

    private var cardBackground: Color {
        switch employee.status {
        case "ONLINE": return Color(hex: "#D7ECD9")
        case "ACTIVE": return Color(hex: "#D0E6F9")
        default: return Color(hex: "#F5F5F5")
        }
    }
}
