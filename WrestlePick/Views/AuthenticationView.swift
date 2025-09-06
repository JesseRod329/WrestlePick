import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthenticationView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.wweBlue)
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isSignUp ? "Join the wrestling community" : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Authentication Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Choose a username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if isSignUp {
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Primary Action Button
                    Button(action: handlePrimaryAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.wweBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    
                    // Social Sign In
                    VStack(spacing: 12) {
                        Text("Or continue with")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            // Apple Sign In
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: handleAppleSignIn
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)
                            
                            // Google Sign In
                            Button(action: handleGoogleSignIn) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.title2)
                                    Text("Continue with Google")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .frame(height: 50)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Guest Mode
                    VStack(spacing: 12) {
                        Text("Want to explore first?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: handleGuestMode) {
                            Text("Continue as Guest")
                                .font(.headline)
                                .foregroundColor(.wweBlue)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Toggle Sign In/Sign Up
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                clearForm()
                            }
                        }) {
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.wweBlue)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setupGoogleSignIn()
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !confirmPassword.isEmpty &&
                   !username.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6 &&
                   isValidEmail(email)
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Action Handlers
    private func handlePrimaryAction() {
        isLoading = true
        
        if isSignUp {
            authService.signUp(email: email, password: password, username: username) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success:
                        // Success handled by AuthService
                        break
                    case .failure(let error):
                        self?.showAlert(error.localizedDescription)
                    }
                }
            }
        } else {
            authService.signIn(email: email, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success:
                        // Success handled by AuthService
                        break
                    case .failure(let error):
                        self?.showAlert(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                // Create Firebase credential
                guard let identityToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: identityToken, encoding: .utf8) else {
                    showAlert("Failed to get Apple ID token")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                        idToken: idTokenString,
                                                        rawNonce: nil)
                
                authService.signInWithCredential(credential, username: fullName?.givenName ?? "User") { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            self?.showAlert(error.localizedDescription)
                        }
                    }
                }
            }
        case .failure(let error):
            showAlert(error.localizedDescription)
        }
    }
    
    private func handleGoogleSignIn() {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            showAlert("Unable to present Google Sign In")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                self?.showAlert(error.localizedDescription)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.showAlert("Failed to get Google ID token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            self?.authService.signInWithCredential(credential, username: user.profile?.name ?? "User") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        self?.showAlert(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func handleGuestMode() {
        authService.signInAsGuest { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self?.showAlert(error.localizedDescription)
                }
            }
        }
    }
    
    private func setupGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
}

// MARK: - Custom Text Field Style
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    AuthenticationView()
}
