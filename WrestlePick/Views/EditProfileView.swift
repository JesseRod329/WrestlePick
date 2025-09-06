import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    VStack(spacing: 16) {
                        Text("Profile Picture")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            // Current Profile Image
                            AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.wweBlue, lineWidth: 3)
                            )
                            
                            // Image Picker
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Text("Change Photo")
                                    .font(.headline)
                                    .foregroundColor(.wweBlue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Profile Information
                    VStack(spacing: 16) {
                        Text("Profile Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            // Display Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter display name", text: $displayName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Tell us about yourself", text: $bio, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                            
                            // Username (Read-only)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Username", text: .constant(authService.currentUser?.username ?? ""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Changes")
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
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: selectedImage) { newValue in
            loadSelectedImage()
        }
        .alert("Profile Update", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !displayName.isEmpty && displayName != authService.currentUser?.displayName
    }
    
    // MARK: - Methods
    private func loadCurrentProfile() {
        displayName = authService.currentUser?.displayName ?? ""
        bio = authService.currentUser?.bio ?? ""
    }
    
    private func loadSelectedImage() {
        guard let selectedImage = selectedImage else { return }
        
        selectedImage.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImage = image
                    }
                }
            case .failure(let error):
                print("Error loading image: \(error)")
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        // For now, we'll just update the text fields
        // In a real app, you'd upload the image to Firebase Storage first
        authService.updateProfile(
            displayName: displayName,
            bio: bio,
            profileImageURL: nil // TODO: Upload image and get URL
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Profile updated successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to update profile: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
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
    EditProfileView()
}
