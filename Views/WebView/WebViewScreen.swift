import SwiftUI
import WebKit
import FirebaseFirestore

// MARK: - WebView UIViewRepresentable
struct WebViewScreen: View {
    let url: String
    var fullLocalJson: String = ""
    var applicationStatus: String = ""
    var company: String = ""
    var subCompanies: [String] = []
    var loginPin: String = ""
    var bbCandidateId: String = ""
    var collectionName: String = "client_sheet_2026"

    @State private var capturedPin: String = ""
    @State private var displayedEmail: String = ""
    @State private var showParamsDialog = false
    @State private var selectedVendor: String = ""
    @State private var selectedLocations: Set<String> = []
    @State private var selectedJobTypes: Set<String> = []
    @State private var passKeyInput: String = ""
    @State private var passKeyError: String = ""
    @State private var availableLocations: [String] = []
    @State private var availableJobTypes: [String] = []
    @State private var webViewRef: WKWebView?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Credentials card
                if !displayedEmail.isEmpty || !capturedPin.isEmpty {
                    credentialsCard
                }

                // Top action buttons
                HStack(spacing: 12) {
                    if applicationStatus == "token_expired" || fullLocalJson.isEmpty {
                        Button("Login") {
                            reloadToAmazonLogin()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button("Execute Service") {
                        loadParamsData()
                        showParamsDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // WebView
                WebViewRepresentable(
                    url: url,
                    fullLocalJson: fullLocalJson,
                    onPinCaptured: { pin in capturedPin = pin },
                    onEmailFound: { email in displayedEmail = email },
                    onDataReceived: { data in storeDataInDatabase(data: data) },
                    onWebViewCreated: { wv in webViewRef = wv }
                )
            }
        }
        .navigationTitle("Web View")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showParamsDialog) {
            paramsSheet
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if selectedVendor.isEmpty {
                selectedVendor = subCompanies.first ?? ""
            }
            // Pre-fill email from fullLocal
            if let data = fullLocalJson.data(using: .utf8),
               let map = try? JSONDecoder().decode([String: String].self, from: data) {
                displayedEmail = map["customerEmail"] ?? map["email"] ?? ""
            }
            capturedPin = loginPin
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Credentials card
    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !displayedEmail.isEmpty {
                HStack {
                    Text("Email: \(displayedEmail)")
                        .font(.caption)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = displayedEmail
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
            }
            if !capturedPin.isEmpty {
                HStack {
                    Text("PIN: \(capturedPin)")
                        .font(.caption.bold())
                    Spacer()
                    Button {
                        UIPasteboard.general.string = capturedPin
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Parameters dialog sheet
    private var paramsSheet: some View {
        NavigationStack {
            Form {
                Section("Vendor") {
                    Picker("Vendor", selection: $selectedVendor) {
                        ForEach(subCompanies, id: \.self) { v in
                            Text(v).tag(v)
                        }
                    }
                }

                Section("Locations") {
                    ForEach(availableLocations, id: \.self) { loc in
                        MultiSelectRow(label: loc, isSelected: selectedLocations.contains(loc)) {
                            if selectedLocations.contains(loc) {
                                selectedLocations.remove(loc)
                            } else {
                                selectedLocations.insert(loc)
                            }
                        }
                    }
                }

                Section("Job Types") {
                    ForEach(availableJobTypes, id: \.self) { jt in
                        MultiSelectRow(label: jt, isSelected: selectedJobTypes.contains(jt)) {
                            if selectedJobTypes.contains(jt) {
                                selectedJobTypes.remove(jt)
                            } else {
                                selectedJobTypes.insert(jt)
                            }
                        }
                    }
                }

                Section("PassKey (optional)") {
                    TextField("xxxx xxxx xxxx xxxx", text: $passKeyInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !passKeyError.isEmpty {
                        Text(passKeyError).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Execute Service")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Run") {
                        if validateAndRun() { showParamsDialog = false }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showParamsDialog = false }
                }
            }
        }
    }

    // MARK: - Helpers
    private func reloadToAmazonLogin() {
        guard let wv = webViewRef else { return }
        wv.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { wv.configuration.websiteDataStore.httpCookieStore.delete($0) }
        }
        let clearJS = "localStorage.clear(); sessionStorage.clear();"
        wv.evaluateJavaScript(clearJS)
        if let loginURL = URL(string: "https://hiring.amazon.ca/app#/login") {
            wv.load(URLRequest(url: loginURL))
        }
    }

    private func loadParamsData() {
        let db = Firestore.firestore()
        db.collection("server_meta_data").document("active_job_data").getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                availableLocations = data["locations"] as? [String] ?? []
                availableJobTypes = data["jobTypes"] as? [String] ?? []
            }
        }
    }

    private func validateAndRun() -> Bool {
        if !passKeyInput.isEmpty {
            let regex = #"^[a-zA-Z0-9]{4} [a-zA-Z0-9]{4} [a-zA-Z0-9]{4} [a-zA-Z0-9]{4}$"#
            if passKeyInput.range(of: regex, options: .regularExpression) == nil {
                passKeyError = "Invalid passKey format (xxxx xxxx xxxx xxxx)"
                return false
            }
        }
        passKeyError = ""
        // Inject execution parameters via JS
        let paramsJson: [String: Any] = [
            "vendor": selectedVendor,
            "locations": Array(selectedLocations),
            "jobTypes": Array(selectedJobTypes),
            "passKey": passKeyInput
        ]
        if let data = try? JSONSerialization.data(withJSONObject: paramsJson),
           let jsonStr = String(data: data, encoding: .utf8) {
            let js = "window.__serviceParams = \(jsonStr); if (window.onServiceParamsReady) window.onServiceParamsReady(\(jsonStr));"
            webViewRef?.evaluateJavaScript(js)
        }
        return true
    }

    // MARK: - Store data in database (mirrors Android storeDataInDatabase)
    private func storeDataInDatabase(data: [String: Any]) {
        guard !bbCandidateId.isEmpty else { return }
        let db = Firestore.firestore()
        let docRef = db.collection(collectionName).document(bbCandidateId)

        docRef.getDocument { snapshot, error in
            guard error == nil else { return }
            let existingData = snapshot?.data() ?? [:]
            let existingStatus = existingData["status"] as? String ?? ""

            // Don't overwrite locked or final states
            let lockedStatuses: Set<String> = ["locked", "FINAL_SUCCESS", "contingent-offer-completed",
                                                "job-opportunities-completed", "general-questions-completed"]
            if lockedStatuses.contains(existingStatus) { return }

            var payload = data
            payload["bbCandidateId"] = bbCandidateId
            if payload["status"] == nil { payload["status"] = "submitted" }

            FirestoreService.shared.addDocument(
                collectionName: collectionName,
                bbCandidateId: bbCandidateId,
                data: payload
            )
        }
    }
}

// MARK: - WKWebView Representable
struct WebViewRepresentable: UIViewRepresentable {
    let url: String
    let fullLocalJson: String
    var onPinCaptured: (String) -> Void
    var onEmailFound: (String) -> Void
    var onDataReceived: ([String: Any]) -> Void
    var onWebViewCreated: (WKWebView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()

        let contentController = config.userContentController
        contentController.add(context.coordinator, name: "AndroidInterface")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        onWebViewCreated(webView)

        if let loadURL = URL(string: url) {
            webView.load(URLRequest(url: loadURL))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewRepresentable
        weak var webView: WKWebView?

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            injectLocalStorage(into: webView)
            installPinCaptureListener(into: webView)
        }

        // Inject fullLocal tokens into localStorage
        private func injectLocalStorage(into webView: WKWebView) {
            guard !parent.fullLocalJson.isEmpty,
                  let data = parent.fullLocalJson.data(using: .utf8),
                  let map = try? JSONDecoder().decode([String: String].self, from: data) else { return }

            var js = ""
            for (key, value) in map {
                guard let keyData = key.data(using: .utf8),
                      let valData = value.data(using: .utf8) else { continue }
                let keyB64 = keyData.base64EncodedString()
                let valB64 = valData.base64EncodedString()
                js += """
                (function(){
                  var k = atob('\(keyB64)');
                  var v = atob('\(valB64)');
                  localStorage.setItem(k, v);
                })();
                """
            }
            if !js.isEmpty {
                webView.evaluateJavaScript(js)
            }
        }

        // Install PIN capture + sendLocalStorage bridge
        private func installPinCaptureListener(into webView: WKWebView) {
            let js = """
            (function(){
              function sendToNative(name, data) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.AndroidInterface) {
                  window.webkit.messageHandlers.AndroidInterface.postMessage({name: name, data: data});
                }
              }
              // Capture PIN input
              document.addEventListener('change', function(e){
                var el = e.target;
                if (el && el.type === 'password' && el.value && el.value.length >= 4) {
                  sendToNative('onPinCaptured', el.value);
                }
              }, true);
              // Export localStorage when page settles
              setTimeout(function(){
                var store = {};
                for (var i = 0; i < localStorage.length; i++) {
                  var k = localStorage.key(i);
                  store[k] = localStorage.getItem(k);
                }
                sendToNative('sendLocalStorage', JSON.stringify(store));
              }, 2000);
            })();
            """
            webView.evaluateJavaScript(js)
        }

        // MARK: WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let name = body["name"] as? String else { return }

            let data = body["data"]

            switch name {
            case "sendLocalStorage":
                if let jsonStr = data as? String,
                   let jsonData = jsonStr.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.parent.onDataReceived(dict)
                    }
                }
            case "onPinCaptured":
                if let pin = data as? String {
                    DispatchQueue.main.async {
                        self.parent.onPinCaptured(pin)
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: - Multi-select row helper
struct MultiSelectRow: View {
    let label: String
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.accentColor)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}
