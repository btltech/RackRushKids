import SwiftUI

struct KidsParentalControlsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("kidsParentalPIN") private var parentalPIN: String = ""
    @AppStorage("kidsOnlinePlayAllowed") private var onlinePlayAllowed: Bool = false
    @AppStorage("kidsOnlineDefinitionsEnabled") private var onlineDefinitionsEnabled: Bool = false
    @AppStorage("kidsExtraChallengeEnabled") private var extraChallengeEnabled: Bool = false
    @AppStorage("kidsHapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("kidsPlaySoundsInSilentMode") private var playSoundsInSilentMode: Bool = false
    
    @ObservedObject private var featureFlags = KidsFeatureFlags.shared
    
    @State private var enteredPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var pinError: String?
    @State private var isUnlocked = false
    @State private var showingTrickyWords = false
    @State private var showingProgressReport = false
    @State private var showingPrivacyPolicy = false
    @State private var showingSupport = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 20) {
                    if parentalPIN.isEmpty {
                        setupPINSection
                    } else if !isUnlocked {
                        unlockSection
                    } else {
                        controlsSection
                    }
                }
                .padding(20)
            }
        }
        .background(KidsTheme.backgroundGradient.ignoresSafeArea())
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(KidsTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(KidsTheme.surface)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Parental Controls")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textPrimary)
            
            Spacer()
            
            Color.clear.frame(width: 36, height: 36)
        }
        .padding()
        .background(KidsTheme.surface)
    }
    
    private var setupPINSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SET PARENT PIN")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            Text("Set a 4-digit PIN so only a parent can change online settings.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 10) {
                pinField(title: "New PIN", text: $newPIN)
                pinField(title: "Confirm PIN", text: $confirmPIN)
                
                if let err = pinError {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
                
                Button(action: setPIN) {
                    Text("Set PIN")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var unlockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENTER PIN")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            VStack(spacing: 10) {
                pinField(title: "PIN", text: $enteredPIN)
                
                if let err = pinError {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }
                
                Button(action: verifyPIN) {
                    Text("Unlock")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KidsTheme.playButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ONLINE SETTINGS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            VStack(spacing: 0) {
                toggleRow(
                    icon: "globe.americas.fill",
                    title: "Online Play",
                    subtitle: onlinePlayAllowed ? "Kids can play online" : "Offline only",
                    isOn: $onlinePlayAllowed
                )
                
                Divider().background(Color.white.opacity(0.1))
                
                toggleRow(
                    icon: "book.fill",
                    title: "Online Word Meanings",
                    subtitle: onlineDefinitionsEnabled ? "Can look up more meanings" : "Offline meanings only",
                    isOn: $onlineDefinitionsEnabled
                )
            }
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Gameplay section (parent-only difficulty tweak)
            Text("GAMEPLAY")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)

            VStack(spacing: 0) {
                toggleRow(
                    icon: "bolt.fill",
                    title: "Extra Challenge",
                    subtitle: extraChallengeEnabled ? "Adds 1 extra letter (ages 7+)" : "Standard letter count",
                    isOn: $extraChallengeEnabled
                )
            }
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            // Audio & Haptics section
            Text("AUDIO & HAPTICS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            VStack(spacing: 0) {
                toggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Haptic Feedback",
                    subtitle: hapticsEnabled ? "Vibrations on" : "Vibrations off",
                    isOn: $hapticsEnabled
                )
                
                Divider().background(Color.white.opacity(0.1))
                
                toggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Play in Silent Mode",
                    subtitle: playSoundsInSilentMode ? "Ignores silent switch" : "Respects silent switch",
                    isOn: $playSoundsInSilentMode
                )
                .onChange(of: playSoundsInSilentMode) { _, _ in
                    KidsAudioManager.shared.refreshAudioSession()
                }
            }
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            // Education section (parent-only learning tools)
            Text("EDUCATION")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            VStack(spacing: 0) {
                Button(action: { showingProgressReport = true }) {
                    linkRow(
                        icon: "chart.bar.fill",
                        label: "Progress Report",
                        value: "View"
                    )
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                Button(action: { showingTrickyWords = true }) {
                    linkRow(
                        icon: "book.fill",
                        label: "Today's Words",
                        value: featureFlags.trickyWordsEnabled ? "View" : "Coming Soon"
                    )
                }
            }
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .sheet(isPresented: $showingProgressReport) {
                ParentProgressReportView()
            }
            .sheet(isPresented: $showingTrickyWords) {
                TrickyWordsView()
            }
            
            // Legal & Support section (parent-only external links)
            Text("LEGAL & SUPPORT")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
                .tracking(1.5)
            
            VStack(spacing: 0) {
                Button(action: { showingPrivacyPolicy = true }) {
                    linkRow(icon: "hand.raised.fill", label: "Privacy Policy", value: "View")
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                Button(action: { showingSupport = true }) {
                    linkRow(icon: "envelope.fill", label: "Support", value: "Contact")
                }
            }
            .background(KidsTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .sheet(isPresented: $showingPrivacyPolicy) {
                KidsMarkdownDocumentView(title: "Privacy Policy", resourceName: "PRIVACY_POLICY", fileExtension: "md")
            }
            .sheet(isPresented: $showingSupport) {
                KidsMarkdownDocumentView(title: "Support", resourceName: "SUPPORT", fileExtension: "md")
            }
            
            Button(action: { isUnlocked = false; enteredPIN = ""; pinError = nil }) {
                Text("Lock")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KidsTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(KidsTheme.textSecondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Color(hex: "3a7bd5"))
        }
        .padding()
    }
    
    private func linkRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(KidsTheme.textSecondary)
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(KidsTheme.textPrimary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(KidsTheme.textMuted)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(KidsTheme.textMuted)
            }
        }
        .padding()
    }
    
    private func pinField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textMuted)
            
            SecureField("••••", text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(12)
                .background(KidsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: text.wrappedValue) { oldValue, newValue in
                    let digitsOnly = newValue.filter(\.isNumber)
                    if digitsOnly.count > 4 {
                        text.wrappedValue = String(digitsOnly.prefix(4))
                    } else if newValue != digitsOnly {
                        text.wrappedValue = digitsOnly
                    }
                }
        }
    }
    
    private func setPIN() {
        pinError = nil
        guard newPIN.count == 4 else {
            pinError = "PIN must be 4 digits."
            return
        }
        guard newPIN == confirmPIN else {
            pinError = "PINs do not match."
            return
        }
        
        parentalPIN = newPIN
        isUnlocked = true
        enteredPIN = ""
        newPIN = ""
        confirmPIN = ""
    }
    
    private func verifyPIN() {
        pinError = nil
        guard enteredPIN == parentalPIN else {
            pinError = "Incorrect PIN."
            return
        }
        isUnlocked = true
        enteredPIN = ""
    }
}

#Preview {
    KidsParentalControlsView()
}

