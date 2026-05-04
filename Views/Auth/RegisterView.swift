import SwiftUI

struct RegisterView: View {
    @State private var viewModel = AuthViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var localError: String?
    @State private var registrationDone = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    Text("Create Account")
                        .font(.largeTitle.bold())

                    VStack(spacing: 16) {
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        TextField("Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        SecureField("Password (min 6 chars)", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }

                    if let error = localError ?? viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    if registrationDone {
                        Text("Registration successful! Your account is pending activation.")
                            .foregroundStyle(.green)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button(action: submit) {
                            Text("Register")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                        }
                    }

                    Button(action: { dismiss() }) {
                        Text("Already have an account? ") + Text("Login").bold()
                    }
                    .font(.footnote)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
            }
        }
        .navigationBarHidden(true)
    }

    private func submit() {
        localError = nil
        guard !name.isEmpty, !email.isEmpty, !phone.isEmpty, !password.isEmpty else {
            localError = "All fields are required."
            return
        }
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }
        viewModel.register(name: name, email: email, password: password, phone: phone) { error in
            if error == nil {
                registrationDone = true
            }
        }
    }
}
