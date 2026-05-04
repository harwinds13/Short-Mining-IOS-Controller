import SwiftUI

struct AdviceLogRowView: View {
    let log: AdviceLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(log.level)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(levelColor.opacity(0.2))
                    .foregroundStyle(levelColor)
                    .cornerRadius(4)

                Text(log.occurredAt)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !log.cityCategory.isEmpty {
                Text("City: \(log.cityCategory)")
                    .font(.caption)
            }

            if !log.serverName.isEmpty {
                Text("Server: \(log.serverName)")
                    .font(.caption)
            }

            if !log.scheduleId.isEmpty {
                Text("Schedule: \(log.scheduleId)")
                    .font(.caption)
            }

            if !log.applicationName.isEmpty {
                Text("App: \(log.applicationName)")
                    .font(.caption)
            }

            if !log.error.isEmpty {
                Text("Error: \(log.error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !log.message.isEmpty {
                Text(log.message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var levelColor: Color {
        switch log.levelEnum {
        case .info: return .green
        case .error: return .red
        case .warning: return .orange
        case .other: return .gray
        }
    }
}
