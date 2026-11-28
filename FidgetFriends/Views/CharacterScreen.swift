import SwiftUI

struct CharacterScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var look = CharacterLook()
    @State private var buddyName = ""
    @State private var nickname = ""
    @State private var savedBanner = false
    @State private var saveFailed = false

    private var hasChanges: Bool {
        guard let profile = store.profile else { return false }
        return profile.look != look || profile.buddyName != buddyName || profile.nickname != nickname
    }

    private var greetingName: String {
        let name = store.profile?.nickname ?? ""
        return name.isEmpty ? "friend" : name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My character")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier("character.title")
                Text("Hi \(greetingName)! Change your buddy any time.")
                    .font(.fun(.headline, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                CharacterBuilder(look: $look, buddyName: $buddyName)
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Your nickname", trailing: "Not added to shared pictures")
                    FunTextField(placeholder: "Nickname", text: $nickname, maxLength: 16)
                        .accessibilityIdentifier("character.nickname")
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(WhimsyBackground(colors: [Palette.cream, Palette.mintPastel.opacity(0.5), Palette.skyPastel]))
        .safeAreaInset(edge: .bottom) {
            Button(savedBanner ? "Saved! ✨" : "Save my buddy") { save() }
                .buttonStyle(.chunky(Palette.grape, shadow: Palette.grapeDeep))
                .disabled(!hasChanges && !savedBanner)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .frame(maxWidth: 760)
                .accessibilityIdentifier("character.save")
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: load)
        .alert("Couldn't save your buddy", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Free up some space, then try again.")
        }
    }

    private func load() {
        guard let profile = store.profile else { return }
        look = profile.look
        buddyName = profile.buddyName
        nickname = profile.nickname
    }

    private func save() {
        guard var profile = store.profile else { return }
        profile.look = look
        profile.buddyName = Profile.resolvedBuddyName(buddyName)
        profile.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard store.saveProfile(profile) else {
            saveFailed = true
            return
        }
        buddyName = profile.buddyName
        nickname = profile.nickname
        savedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { savedBanner = false }
    }
}
