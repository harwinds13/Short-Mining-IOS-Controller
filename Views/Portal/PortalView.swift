import SwiftUI
import FirebaseAuth

struct PortalView: View {
    var authViewModel: AuthViewModel
    @State private var viewModel = PortalViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Vendor profile header
                    profileHeader

                    // Action buttons
                    actionButtons

                    // Service logs (conditional)
                    if viewModel.hasServiceLogsAccess {
                        serviceLogsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Portal")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if let uid = Auth.auth().currentUser?.uid {
                viewModel.loadVendorProfile(userId: uid)
                viewModel.setupLogsListener()
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(viewModel.vendorName.isEmpty ? "Loading..." : viewModel.vendorName, systemImage: "person.fill")
                .font(.headline)
            Label(viewModel.vendorEmail, systemImage: "envelope.fill")
                .font(.subheadline)
            Label(viewModel.vendorPhone, systemImage: "phone.fill")
                .font(.subheadline)
            Label(viewModel.company, systemImage: "building.2.fill")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink {
                WebViewScreen(url: "https://hiring.amazon.ca")
            } label: {
                portalButton(title: "Enable Service", icon: "globe", color: .blue)
            }

            NavigationLink {
                ClientListView(
                    company: viewModel.company,
                    subCompanies: viewModel.subCompanies,
                    collectionName: "client_sheet_2026",
                    hasFormAccess: viewModel.hasFormAccess
                )
            } label: {
                portalButton(title: "Client List", icon: "list.bullet.rectangle", color: .green)
            }

            NavigationLink {
                ClientListView(
                    company: viewModel.company,
                    subCompanies: viewModel.subCompanies,
                    collectionName: "client_sheet_2026_archived",
                    isArchived: true,
                    hasFormAccess: viewModel.hasFormAccess
                )
            } label: {
                portalButton(title: "Archived Clients", icon: "archivebox", color: .gray)
            }

            if viewModel.hasAtozAccess {
                NavigationLink {
                    ATOZClientView()
                } label: {
                    portalButton(title: "ATOZ Clients", icon: "person.3.fill", color: .purple)
                }
            }

            NavigationLink {
                ClientListView(
                    company: viewModel.company,
                    subCompanies: viewModel.subCompanies,
                    collectionName: "client_sheet_2026",
                    vendorFilter: "DUMMY_ONLY",
                    hasFormAccess: viewModel.hasFormAccess
                )
            } label: {
                portalButton(title: "Dummy Clients", icon: "person.crop.circle.badge.questionmark", color: .orange)
            }
        }
    }

    private func portalButton(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .cornerRadius(12)
    }

    // MARK: - Service Logs Section
    private var serviceLogsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Service Logs")
                    .font(.headline)
                Spacer()
                if viewModel.hasPermissionToClearLog {
                    Button(role: .destructive) {
                        viewModel.clearAllLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                            .font(.footnote)
                    }
                }
            }

            if viewModel.logs.isEmpty {
                Text("No logs available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.logs) { log in
                        AdviceLogRowView(log: log)
                        Divider()
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
}
