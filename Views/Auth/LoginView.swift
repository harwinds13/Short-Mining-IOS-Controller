import SwiftUI

struct LoginView: View {
    @State private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text("Short Mining")
                        .font(.largeTitle.bold())

                    Text("Controller Panel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button(action: {
                            viewModel.login(email: email, password: password)
                        }) {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                        }
                    }

                    Button(action: { navigateToRegister = true }) {
                        Text("Don't have an account? ") + Text("Register").bold()
                    }
                    .font(.footnote)

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                PortalView(authViewModel: viewModel)
            }
        }
    }
}
