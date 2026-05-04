import SwiftUI
import FirebaseFirestore

struct CandidateFormView: View {
    let bbCandidateId: String
    let accessToken: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var isFetching = false
    @State private var saveError: String?
    @State private var saveSuccess = false
    @State private var validationError: String?

    // Read-only fields
    @State private var firstName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var rehireEligibility = ""
    @State private var assessments = ""

    // Editable fields
    @State private var workAuthorization = "RestrictedWorkAuth"
    @State private var isProtectedVet = false
    @State private var isMilitarySpouse = false
    @State private var hasCriminalRecord = false
    @State private var previouslyWorkedAmazon = false
    @State private var mostRecentBuilding = ""
    @State private var mostRecentTimePeriod = ""
    @State private var nationalIdType = ""
    @State private var nationalIdNumber = ""

    // Current address
    @State private var houseNumber = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var country = "Canada"
    @State private var countryCode = "CA"
    @State private var zipcode = ""
    @State private var addrFromDate = ""
    @State private var addrToDate = ""

    // Address history (up to 5)
    @State private var addressHistory: [AddressHistoryRow] = []

    private let workAuthOptions = ["RestrictedWorkAuth", "UnrestrictedWorkAuth", "RestrictedWorkAuthWithAdditionalPermit"]
    private let canadianProvinces = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]

    var body: some View {
        NavigationStack {
            Form {
                // Read-only info
                Section("Candidate Info") {
                    LabeledContent("Name", value: firstName.isEmpty ? "—" : firstName)
                    LabeledContent("Email", value: email.isEmpty ? "—" : email)
                    LabeledContent("Phone", value: phoneNumber.isEmpty ? "—" : phoneNumber)
                    if !rehireEligibility.isEmpty {
                        LabeledContent("Rehire Eligibility", value: rehireEligibility)
                    }
                }

                Section("Work Authorization") {
                    Picker("Authorization", selection: $workAuthorization) {
                        ForEach(workAuthOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Additional Info") {
                    Toggle("Protected Veteran", isOn: $isProtectedVet)
                    Toggle("Military Spouse", isOn: $isMilitarySpouse)
                    Toggle("Criminal Record", isOn: $hasCriminalRecord)
                    Toggle("Previously Worked at Amazon", isOn: $previouslyWorkedAmazon)
                    if previouslyWorkedAmazon {
                        TextField("Most Recent Building", text: $mostRecentBuilding)
                        TextField("Most Recent Time Period", text: $mostRecentTimePeriod)
                    }
                }

                Section("National ID") {
                    LabeledContent("ID Type", value: nationalIdType.isEmpty ? "—" : nationalIdType)
                    TextField("ID Number", text: $nationalIdNumber)
                        .autocorrectionDisabled()
                }

                Section("Current Address") {
                    TextField("House Number", text: $houseNumber)
                    TextField("Line 1", text: $line1)
                    TextField("Line 2", text: $line2)
                    TextField("City", text: $city)
                    TextField("State / Province", text: $state)
                    LabeledContent("Country", value: country)
                    LabeledContent("Country Code", value: countryCode)
                    TextField("Postal Code", text: $zipcode)
                    TextField("From (YYYY-MM)", text: $addrFromDate)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("To (YYYY-MM)", text: $addrToDate)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section("Address History") {
                    ForEach($addressHistory) { $row in
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("Province", selection: $row.state) {
                                ForEach(canadianProvinces, id: \.self) { Text($0).tag($0) }
                            }
                            TextField("Country", text: $row.country)
                            LabeledContent("Code", value: row.countryCode)
                            TextField("From (YYYY-MM)", text: $row.fromDate)
                            TextField("To (YYYY-MM)", text: $row.toDate)
                        }
                    }
                    .onDelete { indexSet in
                        addressHistory.remove(atOffsets: indexSet)
                    }
                    if addressHistory.count < 5 {
                        Button("+ Add Address") {
                            addressHistory.append(AddressHistoryRow())
                        }
                    }
                }

                if !assessments.isEmpty {
                    Section("Assessments") {
                        Text(assessments)
                            .font(.caption)
                    }
                }

                if let err = validationError ?? saveError {
                    Section { Text(err).foregroundStyle(.red) }
                }
                if saveSuccess {
                    Section { Text("Saved successfully!").foregroundStyle(.green) }
                }
            }
            .navigationTitle("Candidate Form")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isFetching {
                        ProgressView()
                    } else {
                        Button("Fetch from API") { fetchFromAPI() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save", action: saveForm)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadExistingData() }
        }
    }

    // MARK: - Load existing Firestore data
    private func loadExistingData() {
        Firestore.firestore().collection("form_data").document(bbCandidateId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            populate(from: data)
        }
    }

    // MARK: - Fetch from API
    private func fetchFromAPI() {
        isFetching = true
        Task {
            let api = APIService(accessToken: accessToken)
            if let details = await api.fetchCandidateFullDetails(bbCandidateId: bbCandidateId) {
                await MainActor.run {
                    populate(from: details)
                    isFetching = false
                }
            } else {
                await MainActor.run { isFetching = false }
            }
        }
    }

    // MARK: - Populate form from data dict
    private func populate(from data: [String: Any]) {
        firstName = data["firstName"] as? String ?? firstName
        email = data["email"] as? String ?? data["emailId"] as? String ?? email
        phoneNumber = data["phoneNumber"] as? String ?? phoneNumber
        rehireEligibility = data["rehireEligibility"] as? String ?? rehireEligibility
        workAuthorization = data["workAuthorization"] as? String ?? workAuthorization
        isProtectedVet = data["isProtectedVet"] as? Bool ?? isProtectedVet
        isMilitarySpouse = data["isMilitarySpouse"] as? Bool ?? isMilitarySpouse
        hasCriminalRecord = data["hasCriminalRecord"] as? Bool ?? hasCriminalRecord
        previouslyWorkedAmazon = data["previouslyWorkedAmazon"] as? Bool ?? previouslyWorkedAmazon
        mostRecentBuilding = data["mostRecentBuilding"] as? String ?? mostRecentBuilding
        mostRecentTimePeriod = data["mostRecentTimePeriod"] as? String ?? mostRecentTimePeriod
        nationalIdType = data["nationalIdType"] as? String ?? nationalIdType
        nationalIdNumber = data["nationalIdNumber"] as? String ?? nationalIdNumber
        houseNumber = data["houseNumber"] as? String ?? houseNumber
        line1 = data["line1"] as? String ?? line1
        line2 = data["line2"] as? String ?? line2
        city = data["city"] as? String ?? city
        state = data["state"] as? String ?? state
        zipcode = data["zipcode"] as? String ?? zipcode
        addrFromDate = data["addrFromDate"] as? String ?? addrFromDate
        addrToDate = data["addrToDate"] as? String ?? addrToDate

        if let hist = data["addressHistory"] as? [[String: Any]] {
            addressHistory = hist.compactMap { h -> AddressHistoryRow? in
                var row = AddressHistoryRow()
                row.state = h["state"] as? String ?? ""
                row.country = h["country"] as? String ?? ""
                row.countryCode = h["countryCode"] as? String ?? "CA"
                row.fromDate = h["fromDate"] as? String ?? ""
                row.toDate = h["toDate"] as? String ?? ""
                return row
            }
        }

        if let assess = data["assessments"] as? [String: Any] {
            assessments = assess.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        }
    }

    // MARK: - Validate
    private func validate() -> Bool {
        let yearMonthRegex = #"^\d{4}-\d{2}$"#
        for dateStr in [addrFromDate, addrToDate].filter({ !$0.isEmpty }) {
            if dateStr.range(of: yearMonthRegex, options: .regularExpression) == nil {
                validationError = "Dates must be YYYY-MM format."
                return false
            }
        }
        if !addrFromDate.isEmpty && !addrToDate.isEmpty && addrToDate < addrFromDate {
            validationError = "Address end date must be >= start date."
            return false
        }
        for row in addressHistory {
            if !row.fromDate.isEmpty && row.fromDate.range(of: yearMonthRegex, options: .regularExpression) == nil {
                validationError = "History dates must be YYYY-MM format."
                return false
            }
            if !row.fromDate.isEmpty && !row.toDate.isEmpty && row.toDate < row.fromDate {
                validationError = "History end date must be >= start date."
                return false
            }
        }
        validationError = nil
        return true
    }

    // MARK: - Save form
    private func saveForm() {
        guard validate() else { return }
        isLoading = true
        saveError = nil
        saveSuccess = false

        let data: [String: Any] = [
            "firstName": firstName,
            "email": email,
            "phoneNumber": phoneNumber,
            "workAuthorization": workAuthorization,
            "isProtectedVet": isProtectedVet,
            "isMilitarySpouse": isMilitarySpouse,
            "hasCriminalRecord": hasCriminalRecord,
            "previouslyWorkedAmazon": previouslyWorkedAmazon,
            "mostRecentBuilding": mostRecentBuilding,
            "mostRecentTimePeriod": mostRecentTimePeriod,
            "nationalIdType": nationalIdType,
            "nationalIdNumber": nationalIdNumber,
            "houseNumber": houseNumber,
            "line1": line1,
            "line2": line2,
            "city": city,
            "state": state,
            "country": country,
            "countryCode": countryCode,
            "zipcode": zipcode,
            "addrFromDate": addrFromDate,
            "addrToDate": addrToDate,
            "addressHistory": addressHistory.map { [
                "state": $0.state,
                "country": $0.country,
                "countryCode": $0.countryCode,
                "fromDate": $0.fromDate,
                "toDate": $0.toDate
            ] }
        ]

        FirestoreService.shared.saveFormData(
            collectionName: "form_data",
            bbCandidateId: bbCandidateId,
            formData: data
        ) { error in
            isLoading = false
            if let error = error {
                saveError = error.localizedDescription
            } else {
                saveSuccess = true
            }
        }
    }
}

// MARK: - Address History Row model
struct AddressHistoryRow: Identifiable {
    var id = UUID()
    var state: String = ""
    var country: String = "Canada"
    var countryCode: String = "CA"
    var fromDate: String = ""
    var toDate: String = ""
}
