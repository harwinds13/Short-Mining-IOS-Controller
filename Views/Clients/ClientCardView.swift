import SwiftUI

struct ClientCardView: View {
    let client: Client
    let collectionName: String
    let isArchived: Bool
    let hasFormAccess: Bool
    let company: String
    let subCompanies: [String]

    @State private var showWebView = false
    @State private var showForm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM, hh:mm a"
        f.locale = Locale.current
        f.timeZone = TimeZone.current
        return f
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardBackground
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                // Header row: pod / status light
                HStack {
                    Text(client.pod.isEmpty ? client.bbCandidateId : client.pod)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusLight
                }

                Text(client.clientName.isEmpty ? "—" : client.clientName)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                // Email with copy
                HStack(spacing: 4) {
                    Text(client.clientEmail.isEmpty ? "—" : client.clientEmail)
                        .font(.caption)
                        .lineLimit(1)
                    if !client.clientEmail.isEmpty {
                        Button {
                            UIPasteboard.general.string = client.clientEmail
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !client.clientPhoneNumber.isEmpty {
                    Text(client.clientPhoneNumber)
                        .font(.caption)
                }

                if !client.location.isEmpty {
                    Text(client.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !client.jobType.isEmpty {
                    Text(client.jobType)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Status badge
                Text(client.status)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusBadgeColor.opacity(0.2))
                    .foregroundStyle(statusBadgeColor)
                    .cornerRadius(4)

                // Expire time
                if client.expireTime > 0 {
                    let date = Date(timeIntervalSince1970: Double(client.expireTime) / 1000)
                    Text(Self.dateFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Auto login warning
                if client.autoLoginAttempt == "FAILED" || client.autoLoginAttempt == "STOPPED" {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text("Try manually")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(10)
        }
        .contextMenu {
            if hasFormAccess {
                Button {
                    showForm = true
                } label: {
                    Label("Open Form", systemImage: "doc.text")
                }
            }

            if !isArchived {
                Button {
                    FirestoreService.shared.archiveClient(
                        sourceCollection: collectionName,
                        archivedCollection: collectionName + "_archived",
                        bbCandidateId: client.bbCandidateId
                    ) { _ in }
                } label: {
                    Label("Mark as Done", systemImage: "checkmark.circle")
                }
            } else {
                Button {
                    FirestoreService.shared.unarchiveClient(
                        archivedCollection: collectionName,
                        sourceCollection: "client_sheet_2026",
                        bbCandidateId: client.bbCandidateId
                    ) { _ in }
                } label: {
                    Label("Mark as Undone", systemImage: "arrow.uturn.backward.circle")
                }
            }

            if client.autoLoginAttempt == "FAILED" || client.autoLoginAttempt == "STOPPED" {
                Button {
                    FirestoreService.shared.updateAutoLoginAttempt(
                        collectionName: collectionName,
                        bbCandidateId: client.bbCandidateId,
                        newAttempt: "PASSED"
                    )
                } label: {
                    Label("Auto Re-Login", systemImage: "arrow.clockwise")
                }
            }

            if client.autoLoginAttempt == "PASSED" {
                Button {
                    FirestoreService.shared.updateAutoLoginAttempt(
                        collectionName: collectionName,
                        bbCandidateId: client.bbCandidateId,
                        newAttempt: "STOPPED"
                    )
                } label: {
                    Label("Stop Auto Re-Login", systemImage: "stop.circle")
                }
            }
        }
        .onTapGesture {
            if canNavigateToWebView {
                showWebView = true
            }
        }
        .navigationDestination(isPresented: $showWebView) {
            let fullLocalJson = (try? JSONEncoder().encode(client.fullLocal)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            WebViewScreen(
                url: "https://hiring.amazon.ca",
                fullLocalJson: fullLocalJson,
                applicationStatus: client.status,
                company: company,
                subCompanies: subCompanies,
                loginPin: client.loginPin,
                bbCandidateId: client.bbCandidateId,
                collectionName: collectionName
            )
        }
        .navigationDestination(isPresented: $showForm) {
            ClientFormView(
                client: client,
                collectionName: collectionName,
                company: company,
                subCompanies: subCompanies
            )
        }
    }

    // MARK: - Background colour by status
    private var cardBackground: Color {
        switch client.status {
        case "FINAL_SUCCESS", "contingent-offer-completed", "job-opportunities-completed", "general-questions-completed":
            return Color(hex: "#D7ECD9")
        case "locked":
            return Color(hex: "#D0E6F9")
        case "token_expired", "system_interrupt", "generic_error":
            return Color(hex: "#FBDCDC")
        default:
            return Color(hex: "#F5F5F5")
        }
    }

    // MARK: - Status badge colour
    private var statusBadgeColor: Color {
        switch client.status {
        case "FINAL_SUCCESS", "contingent-offer-completed", "job-opportunities-completed", "general-questions-completed":
            return .green
        case "locked":
            return .blue
        case "token_expired", "system_interrupt", "generic_error":
            return .red
        default:
            return .gray
        }
    }

    // MARK: - Status light (only if passKey & pin are both non-empty)
    @ViewBuilder
    private var statusLight: some View {
        if !client.passKey.isEmpty && !client.pin.isEmpty {
            Circle()
                .fill(statusLightColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusLightColor.opacity(0.6), radius: 3)
        }
    }

    private var statusLightColor: Color {
        switch client.pin {
        case "PASSED": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "WAITING": return .yellow
        default: return .red
        }
    }

    // MARK: - Navigate to WebView condition
    private var canNavigateToWebView: Bool {
        let navigableStatuses: Set<String> = [
            "submitted", "token_expired", "FINAL_SUCCESS",
            "contingent-offer-completed", "job-opportunities-completed", "general-questions-completed"
        ]
        return navigableStatuses.contains(client.status)
    }
}

// MARK: - Hex color helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
