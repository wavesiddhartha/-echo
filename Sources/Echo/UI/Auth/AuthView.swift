import SwiftUI

public struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSignUp: Bool = false
    @State private var email: String = "admin@echo.ai"
    @State private var password: String = "admin12345"
    @State private var fullName: String = "Siddhartha"
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var showPassword: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            if let user = SupabaseManager.shared.currentUser, SupabaseManager.shared.isAuthenticated {
                accountDashboardView(user: user)
            } else {
                loginAndSignUpView
            }
        }

        .frame(width: 440, height: 530)
        .background(Color.white)
        .preferredColorScheme(.light)
    }
    
    // MARK: - 1. Authenticated Account & Sign-Out Dashboard
    @ViewBuilder
    private func accountDashboardView(user: SupabaseUser) -> some View {
        VStack(spacing: 20) {
            // Header Bar
            HStack {
                Text("echo")
                    .font(.custom("AguafinaScript-Regular", size: 30))
                    .foregroundColor(Color(hex: "#18181B"))
                    .baselineOffset(-2)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#A1A1AA"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Divider().background(Color(hex: "#E8E6DF"))
            
            // Profile Card
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#18181B"))
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    
                    Text(user.fullName?.prefix(1) ?? "S")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.fullName ?? "Siddhartha")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#18181B"))
                        
                        if user.isAdmin {
                            Text("ADMIN")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#D97706"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color(hex: "#FEF3C7")))
                        }
                    }
                    
                    Text(user.email)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#71717A"))
                }
                
                // Cloud Status Badge
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "#10B981")).frame(width: 6, height: 6)
                    Text("Supabase Cloud Connected • Realtime Active")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#059669"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color(hex: "#D1FAE5")))
            }
            .padding(.vertical, 6)
            
            // System Stats Grid
            HStack(spacing: 12) {
                statBox(title: "Auth Tier", value: user.isAdmin ? "Pro Admin" : "Creator", icon: "shield.fill")
                statBox(title: "Database", value: "Supabase PG", icon: "cylinder.split.1x2.fill")
                statBox(title: "Sync Mode", value: "Realtime", icon: "bolt.fill")
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Actions: Force Sync & Sign Out
            VStack(spacing: 10) {
                Button(action: {
                    Task {
                        try? await SupabaseManager.shared.syncSessionToCloud(Session(title: "Manual Sync Check"))
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Force Realtime Cloud Sync")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(Color(hex: "#18181B"))
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "#EDEAE1"))
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    SoundFeedbackManager.shared.playActivationHaptic()
                    SupabaseManager.shared.signOut()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("Sign Out from Echo")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(Color(hex: "#EF4444"))
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "#FEE2E2"))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
    }
    
    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#71717A"))
                Text(title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color(hex: "#71717A"))
            }
            
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#18181B"))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "#F7F5EE"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color(hex: "#E8E6DF"), lineWidth: 0.75)
                )
        )
    }
    
    // MARK: - 2. Login & Sign Up Form View
    @ViewBuilder
    private var loginAndSignUpView: some View {
        VStack(spacing: 16) {
            // Header with Wordmark
            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#A1A1AA"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)
                .padding(.trailing, 16)
                
                Text("echo")
                    .font(.custom("AguafinaScript-Regular", size: 36))
                    .foregroundColor(Color(hex: "#18181B"))
                    .baselineOffset(-2)
                
                Text(isSignUp ? "Create your Echo Cloud Account" : "Sign In to Echo Intelligence")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#18181B"))
                
                Text("Realtime Supabase Cloud database with encrypted Keychain auth.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#71717A"))
                    .multilineTextAlignment(.center)
            }
            
            // Tab Switcher
            HStack(spacing: 4) {
                tabButton(title: "Sign In", active: !isSignUp) {
                    isSignUp = false
                    errorMessage = nil
                }
                
                tabButton(title: "Create Account", active: isSignUp) {
                    isSignUp = true
                    errorMessage = nil
                }
            }
            .padding(3)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(hex: "#EDEAE1"))
            )
            
            // Quick 1-Click Demo Admin Button
            if !isSignUp {
                Button(action: {
                    email = "admin@echo.ai"
                    password = "admin12345"
                    handleAuthAction()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#D97706"))
                        Text("1-Click Sign In as Admin (admin@echo.ai)")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#92400E"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(hex: "#FEF3C7"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color(hex: "#FDE68A"), lineWidth: 0.75)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            
            // Inputs
            VStack(alignment: .leading, spacing: 10) {
                if isSignUp {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Full Name")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#18181B"))
                        TextField("Siddhartha", text: $fullName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Email Address")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                    TextField("admin@echo.ai", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12.5))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Password")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#18181B"))
                        Spacer()
                        Button(action: { showPassword.toggle() }) {
                            Text(showPassword ? "Hide" : "Show")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(Color(hex: "#71717A"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if showPassword {
                        TextField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))
                    } else {
                        SecureField("••••••••••••", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))
                    }
                }
            }
            .padding(.horizontal, 24)
            
            if let error = errorMessage {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundColor(Color(hex: "#EF4444"))
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Primary Submit Button
            Button(action: handleAuthAction) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView().controlSize(.small).colorInvert()
                    } else {
                        Text(isSignUp ? "Create Account & Connect" : "Sign In with Supabase")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: "#18181B"))
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading || email.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    private func tabButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundFeedbackManager.shared.playActivationHaptic()
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: active ? .bold : .medium, design: .rounded))
                .foregroundColor(active ? Color.white : Color(hex: "#71717A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(active ? Color(hex: "#18181B") : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func handleAuthAction() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    _ = try await SupabaseManager.shared.signUp(email: email, password: password, fullName: fullName)
                } else {
                    _ = try await SupabaseManager.shared.signIn(email: email, password: password)
                }
                SoundFeedbackManager.shared.playSuccessHaptic()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
