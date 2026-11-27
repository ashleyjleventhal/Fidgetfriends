import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var saveFailed = false
    @AccessibilityFocusState private var progressFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 46

    private var step: Int { store.setupDraft.step }

    var body: some View {
        ZStack {
            WhimsyBackground(colors: [Palette.cream, Palette.sunshinePastel.opacity(0.6), Palette.lilac])
            ScrollView {
                VStack(spacing: 24) {
                    progress
                    switch step {
                    case 0: welcome
                    case 1: nameStep
                    default: buildStep
                    }
                }
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .id(step)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if step == 2 {
                    buildActions
                }
            }
        }
        .onChange(of: step) { _, _ in progressFocused = true }
        .alert("Couldn't save your setup", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Free up some space, then try again.")
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= step ? Palette.grape : Palette.lilac)
                    .frame(width: index == step ? 34 : 12, height: 12)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of 3")
        .accessibilityAddTraits(.isHeader)
        .accessibilityFocused($progressFocused)
        .accessibilityIdentifier("onboarding.progress")
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            HStack(spacing: -24) {
                CritterView(species: .cat, color: .tangerine, eyes: .sparkle, mouth: .kitty).frame(width: 120)
                CritterView(species: .blob, color: .grape, eyes: .sparkle, mouth: .grin, accessory: .crown).frame(width: 170).zIndex(1)
                CritterView(species: .frog, color: .mint, eyes: .dots, mouth: .tongue).frame(width: 120)
            }
            Text("Fidget Friends")
                .font(.system(size: titleSize, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(LinearGradient(colors: [Palette.grape, Palette.coralDeep], startPoint: .leading, endPoint: .trailing))
            Text("Catalog every squishy and fidget you love, then make a happy picture of your shelf!")
                .font(.fun(.title3, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Label("No accounts. The app never uploads your collection.", systemImage: "lock.fill")
                .font(.fun(.footnote))
                .foregroundStyle(Palette.grape)
            Button { store.setupDraft.step = 1 } label: {
                Label("Make my buddy", systemImage: "arrow.right")
            }
            .buttonStyle(.chunky)
            .accessibilityIdentifier("onboarding.start")
        }
        .padding(.top, 20)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Hi, friend!")
                .font(.fun(.largeTitle, weight: .black))
                .foregroundStyle(Palette.ink)
            Text("Add a nickname or keep going. Shared pictures leave it out. Your device may back up app data.")
                .font(.fun(.body, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
            FunTextField(placeholder: "Nickname (optional)", text: $store.setupDraft.nickname, maxLength: 16)
                .textContentType(.nickname)
                .accessibilityIdentifier("onboarding.nickname")
            Toggle(isOn: $store.setupDraft.addSamples) {
                Text("Start with a few example toys").font(.fun(.headline)).foregroundStyle(Palette.ink)
            }
            .tint(Palette.mintDeep)
            .padding(16)
            .stickerCard()
            .accessibilityIdentifier("onboarding.samples")
            Button { store.setupDraft.step = 2 } label: {
                Label("Next", systemImage: "arrow.right")
            }
            .buttonStyle(.chunky)
            .accessibilityIdentifier("onboarding.next")
            Button("Back") { store.setupDraft.step = 0 }
                .font(.fun(.headline))
                .frame(maxWidth: .infinity)
        }
    }

    private var buildStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Make your buddy!")
                .font(.fun(.largeTitle, weight: .black))
                .foregroundStyle(Palette.ink)
            CharacterBuilder(look: $store.setupDraft.look, buddyName: $store.setupDraft.buddyName)
        }
    }

    private var buildActions: some View {
        HStack(spacing: 12) {
            Button { store.setupDraft.step = 1 } label: {
                Image(systemName: "chevron.left")
                    .accessibilityLabel("Back")
            }
            .buttonStyle(.chunky(.white, shadow: Palette.lilac, foreground: Palette.grape, fullWidth: false))

            Button { finish() } label: {
                Label("To my shelf", systemImage: "checkmark")
            }
            .buttonStyle(.chunky(Palette.coral, shadow: Palette.coralDeep, foreground: Palette.ink))
            .accessibilityIdentifier("onboarding.finish")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(Palette.cream.ignoresSafeArea(edges: .bottom))
    }

    private func finish() {
        let draft = store.setupDraft
        let profile = Profile(
            nickname: draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            buddyName: Profile.resolvedBuddyName(draft.buddyName),
            look: draft.look
        )
        saveFailed = !store.saveProfile(profile, addSamples: draft.addSamples)
    }
}
