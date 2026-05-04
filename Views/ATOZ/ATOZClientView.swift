import SwiftUI

private let availableServers = [
    "cad_on_bramptn_turtle_01",
    "cad_ab_calgary_naadrv_02",
    "cad_on_bramptn_harcirc_01",
    "cad_on_bramptn_nanport_01",
    "cad_on_bramptn_frndle_01"
]

private let allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private let allPriorityOrders = ["priority_full_shifts", "priority_half_shifts", "full_shifts", "half_shifts", "extended"]

struct ATOZClientView: View {
    @State private var viewModel = ATOZViewModel()
    @State private var selectedEmployee: ATOZEmployee?
    @State private var showEditSheet = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.employees.isEmpty {
                VStack {
                    Spacer()
                    Text("No ATOZ employees found.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading) {
                    Text("\(viewModel.employees.count) employee(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.employees) { emp in
                                ATOZEmployeeCard(employee: emp) {
                                    selectedEmployee = emp
                                    showEditSheet = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("ATOZ Clients")
        .onAppear { viewModel.fetchEmployees() }
        .sheet(isPresented: $showEditSheet) {
            if let emp = selectedEmployee {
                ATOZEditSheet(employee: emp, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Edit Sheet
struct ATOZEditSheet: View {
    @State var employee: ATOZEmployee
    var viewModel: ATOZViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $employee.name)
                    TextField("Site ID", text: $employee.siteID)
                }

                Section("Server") {
                    Picker("Server", selection: $employee.server) {
                        ForEach(availableServers, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Shift Preferences") {
                    Toggle("Shift Type: Vet", isOn: $employee.isShiftTypeVet)
                    Toggle("Full Shift Prefer Prior Day", isOn: $employee.isFullShiftPreferInPriorDay)
                    Toggle("Half Shift Prefer Prior Day", isOn: $employee.isHalfShiftPreferInPriorDay)
                }

                Section("Priority Days (tap to toggle order)") {
                    ForEach(allDays, id: \.self) { day in
                        let idx = employee.priorityDays.firstIndex(of: day)
                        Button(action: {
                            if let i = idx {
                                employee.priorityDays.remove(at: i)
                            } else {
                                employee.priorityDays.append(day)
                            }
                        }) {
                            HStack {
                                Text(day)
                                Spacer()
                                if let i = idx {
                                    Text("#\(i + 1)")
                                        .foregroundStyle(.accentColor)
                                        .font(.caption.bold())
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Priority Order (tap to toggle order)") {
                    ForEach(allPriorityOrders, id: \.self) { po in
                        let idx = employee.priorityOrder.firstIndex(of: po)
                        Button(action: {
                            if let i = idx {
                                employee.priorityOrder.remove(at: i)
                            } else {
                                employee.priorityOrder.append(po)
                            }
                        }) {
                            HStack {
                                Text(po)
                                Spacer()
                                if let i = idx {
                                    Text("#\(i + 1)")
                                        .foregroundStyle(.accentColor)
                                        .font(.caption.bold())
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.logoutEmployee(emp: employee)
                        dismiss()
                    } label: {
                        Label("Logout Employee", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Edit Employee")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updates: [String: Any] = [
                            "name": employee.name,
                            "siteID": employee.siteID,
                            "server": employee.server,
                            "isShiftTypeVet": employee.isShiftTypeVet,
                            "isFullShiftPreferInPriorDay": employee.isFullShiftPreferInPriorDay,
                            "isHalfShiftPreferInPriorDay": employee.isHalfShiftPreferInPriorDay,
                            "priorityDays": employee.priorityDays,
                            "priorityOrder": employee.priorityOrder
                        ]
                        viewModel.saveEmployee(emp: employee, updates: updates)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
