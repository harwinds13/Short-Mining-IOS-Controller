import SwiftUI

struct ClientListView: View {
    let company: String
    let subCompanies: [String]
    var collectionName: String = "client_sheet_2026"
    var vendorFilter: String? = nil
    var isArchived: Bool = false
    var hasFormAccess: Bool = false

    @State private var viewModel = ClientListViewModel()
    @State private var showFilterDialog = false

    private let filterOptions = [
        "All", "submitted", "locked", "FINAL_SUCCESS",
        "job-opportunities-completed", "contingent-offer-completed",
        "general-questions-completed"
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            StatusBarView(
                finishedCount: viewModel.finishedCount,
                errorCount: viewModel.errorCount,
                processingCount: viewModel.processingCount,
                lockedCount: viewModel.otherCount,
                totalCount: viewModel.clients.count
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredClients.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.clients.isEmpty ? "No clients found." : "No results for current filter/search.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredClients) { client in
                            ClientCardView(
                                client: client,
                                collectionName: collectionName,
                                isArchived: isArchived,
                                hasFormAccess: hasFormAccess,
                                company: company,
                                subCompanies: subCompanies
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(isArchived ? "Archived Clients" : "Client List")
        .searchable(text: $viewModel.searchQuery, prompt: "Search clients…")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilterDialog = true
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .confirmationDialog("Filter by Status", isPresented: $showFilterDialog) {
            ForEach(filterOptions, id: \.self) { option in
                Button(option) { viewModel.applyFilter(option) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            viewModel.hasFormAccess = hasFormAccess
            viewModel.fetchClients(
                company: company,
                subCompanies: subCompanies,
                collectionName: collectionName,
                vendorFilter: vendorFilter
            )
        }
    }
}
