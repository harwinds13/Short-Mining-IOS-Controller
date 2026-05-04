import SwiftUI
import FirebaseFirestore

struct ClientFormView: View {
    let client: Client
    let collectionName: String
    let company: String
    let subCompanies: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false

    // Editable fields
    @State private var pod: String
    @State private var pin: String
    @State private var passKey: String
    @State private var status: String
    @State private var autoLoginAttempt: String
    @State private var cityCategory: String

    // Cascading job picker
    @State private var availableStates: [String] = []
    @State private var availableCities: [String] = []
    @State private var availableJobTypes: [String] = []
    @State private var availableSchedules: [JobSchedule] = []

    @State private var selectedState: String = ""
    @State private var selectedCity: String = ""
    @State private var selectedJobType: String = ""
    @State private var selectedSchedule: JobSchedule?

    @State private var allSchedules: [JobSchedule] = []
    @State private var saveError: String?
    @State private var saveSuccess = false

    private let cityCategoryOptions = ["GTA_ACTIVE", "BC_ACTIVE", "OTT_ACTIVE", "CAL_ACTIVE", "LON_ACTIVE"]
    private let statusOptions = ["submitted", "locked", "token_expired", "FINAL_SUCCESS",
                                  "job-opportunities-completed", "contingent-offer-completed",
                                  "general-questions-completed", "system_interrupt", "generic_error"]
    private let autoLoginOptions = ["PASSED", "WAITING", "FAILED", "STOPPED"]

    init(client: Client, collectionName: String, company: String, subCompanies: [String]) {
        self.client = client
        self.collectionName = collectionName
        self.company = company
        self.subCompanies = subCompanies
        _pod = State(initialValue: client.pod)
        _pin = State(initialValue: client.pin)
        _passKey = State(initialValue: client.passKey)
        _status = State(initialValue: client.status)
        _autoLoginAttempt = State(initialValue: client.autoLoginAttempt)
        _cityCategory = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Info") {
                    TextField("POD", text: $pod)
                    Picker("City Category", selection: $cityCategory) {
                        Text("None").tag("")
                        ForEach(cityCategoryOptions, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("PIN", text: $pin)
                    TextField("PassKey", text: $passKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Auto Login Attempt", selection: $autoLoginAttempt) {
                        ForEach(autoLoginOptions, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Job Selection") {
                    if availableStates.isEmpty {
                        Text("Loading schedules…").foregroundStyle(.secondary)
                    } else {
                        Picker("State", selection: $selectedState) {
                            Text("— Select —").tag("")
                            ForEach(availableStates, id: \.self) { Text($0).tag($0) }
                        }
                        .onChange(of: selectedState) { _, _ in updateCities() }

                        if !selectedState.isEmpty {
                            Picker("City", selection: $selectedCity) {
                                Text("— Select —").tag("")
                                ForEach(availableCities, id: \.self) { Text($0).tag($0) }
                            }
                            .onChange(of: selectedCity) { _, _ in updateJobTypes() }
                        }

                        if !selectedCity.isEmpty {
                            Picker("Job Type", selection: $selectedJobType) {
                                Text("— Select —").tag("")
                                ForEach(availableJobTypes, id: \.self) { Text($0).tag($0) }
                            }
                            .onChange(of: selectedJobType) { _, _ in updateSchedules() }
                        }

                        if !selectedJobType.isEmpty {
                            Picker("Schedule", selection: $selectedSchedule) {
                                Text("— Select —").tag(nil as JobSchedule?)
                                ForEach(availableSchedules) { s in
                                    Text("\(s.scheduleId) | \(s.siteId) | \(s.laborDemandAvailableCount)")
                                        .tag(s as JobSchedule?)
                                }
                            }
                        }
                    }
                }

                if let err = saveError {
                    Section { Text(err).foregroundStyle(.red) }
                }
                if saveSuccess {
                    Section { Text("Saved successfully!").foregroundStyle(.green) }
                }

                Section {
                    Button(role: .destructive) {
                        logoutClient()
                    } label: {
                        Label("Logout Client", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Edit Client")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save", action: save)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadSchedules() }
        }
    }

    // MARK: - Load schedules
    private func loadSchedules() {
        isLoading = true
        Firestore.firestore().collection("current_avail_job_schdules").getDocuments { snapshot, _ in
            isLoading = false
            allSchedules = snapshot?.documents.compactMap { doc -> JobSchedule? in
                let d = doc.data()
                return JobSchedule(
                    id: doc.documentID,
                    city: d["City"] as? String ?? "",
                    state: d["State"] as? String ?? "",
                    scheduleId: d["scheduleId"] as? String ?? "",
                    siteId: d["siteId"] as? String ?? "",
                    address: d["Address"] as? String ?? "",
                    scheduleType: d["scheduleType"] as? String ?? "",
                    laborDemandAvailableCount: d["laborDemandAvailableCount"] as? String ?? "0",
                    jobType: d["jobType"] as? String ?? ""
                )
            } ?? []
            availableStates = Array(Set(allSchedules.map { $0.state })).sorted()
        }
    }

    private func updateCities() {
        availableCities = Array(Set(allSchedules.filter { $0.state == selectedState }.map { $0.city })).sorted()
        selectedCity = ""
        selectedJobType = ""
        selectedSchedule = nil
    }

    private func updateJobTypes() {
        availableJobTypes = Array(Set(allSchedules.filter { $0.state == selectedState && $0.city == selectedCity }.map { $0.jobType })).sorted()
        selectedJobType = ""
        selectedSchedule = nil
    }

    private func updateSchedules() {
        availableSchedules = allSchedules.filter {
            $0.state == selectedState && $0.city == selectedCity && $0.jobType == selectedJobType
        }
        selectedSchedule = nil
    }

    // MARK: - Save
    private func save() {
        isLoading = true
        saveError = nil
        saveSuccess = false

        var updates: [String: Any] = [
            "pod": pod,
            "pin": pin,
            "passKey": passKey,
            "status": status,
            "autoLoginAttempt": autoLoginAttempt
        ]

        if !cityCategory.isEmpty { updates["cityCategory"] = cityCategory }

        if let sch = selectedSchedule {
            updates["job"] = sch.scheduleId
            updates["sch"] = sch.scheduleId
            updates["location"] = sch.city
            updates["jobType"] = sch.jobType
            updates["jobDetails"] = [
                "city": sch.city,
                "state": sch.state,
                "scheduleId": sch.scheduleId,
                "siteId": sch.siteId,
                "address": sch.address,
                "scheduleType": sch.scheduleType,
                "laborDemandAvailableCount": sch.laborDemandAvailableCount,
                "jobType": sch.jobType
            ]
        }

        FirestoreService.shared.saveFormData(
            collectionName: collectionName,
            bbCandidateId: client.bbCandidateId,
            formData: updates
        ) { error in
            isLoading = false
            if let error = error {
                saveError = error.localizedDescription
            } else {
                saveSuccess = true
            }
        }
    }

    // MARK: - Logout client
    private func logoutClient() {
        FirestoreService.shared.saveFormData(
            collectionName: collectionName,
            bbCandidateId: client.bbCandidateId,
            formData: ["status": "token_expired", "accessToken": ""]
        ) { _ in dismiss() }
    }
}

// MARK: - Job Schedule model
struct JobSchedule: Identifiable, Hashable {
    var id: String
    var city: String
    var state: String
    var scheduleId: String
    var siteId: String
    var address: String
    var scheduleType: String
    var laborDemandAvailableCount: String
    var jobType: String
}
