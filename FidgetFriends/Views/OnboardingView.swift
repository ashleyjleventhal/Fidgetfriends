import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step = 0
    @State private var nickname = ""
    @State private var buddyName = "Pip"
    @State private var look = CharacterLook()
    @State private var addSamples = true

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
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
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
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            HStack(spacing: -24) {
                CritterView(species: .cat, color: .tangerine, eyes: .sparkle, mouth: .kitty).frame(width: 120)
                CritterView(species: .blob, color: .grape, eyes: .sparkle, mouth: .grin, accessory: .crown).frame(width: 170).zIndex(1)
                CritterView(species: .frog, color: .mint, eyes: .dots, mouth: .tongue).frame(width: 120)
            }
            Text("Fidget Friends")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Palette.grape, Palette.coralDeep], startPoint: .leading, endPoint: .trailing))
            Text("Catalog every squishy and fidget you love, then make a happy picture of your shelf!")
                .font(.fun(.title3, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Label("No accounts. The app never uploads your collection.", systemImage: "lock.fill")
                .font(.fun(.footnote))
                .foregroundStyle(Palette.grape)
            Button("Let's make my buddy!") { step = 1 }
                .buttonStyle(.chunky)
                .accessibilityIdentifier("onboarding.start")
        }
        .padding(.top, 20)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Hi there! What should we call you?")
                .font(.fun(.largeTitle, weight: .black))
                .foregroundStyle(Palette.ink)
            Text("A first name or a fun nickname. The app keeps it on this device and never puts it in pictures you share.")
                .font(.fun(.body, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
            FunTextField(placeholder: "Nickname", text: $nickname, maxLength: 16)
                .textContentType(.nickname)
                .accessibilityIdentifier("onboarding.nickname")
            Toggle(isOn: $addSamples) {
                Text("Start with a few example toys").font(.fun(.headline)).foregroundStyle(Palette.ink)
            }
            .tint(Palette.mintDeep)
            .padding(16)
            .stickerCard()
            .accessibilityIdentifier("onboarding.samples")
            Button("Next") { step = 2 }
                .buttonStyle(.chunky)
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("onboarding.next")
            Button("Back") { step = 0 }
                .font(.fun(.headline))
                .frame(maxWidth: .infinity)
        }
    }

    private var buildStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Make your squishy buddy!")
                .font(.fun(.largeTitle, weight: .black))
                .foregroundStyle(Palette.ink)
            CharacterBuilder(look: $look, buddyName: $buddyName)
            Button("All done — to my shelf!") { finish() }
                .buttonStyle(.chunky(Palette.coral, shadow: Palette.coralDeep))
                .accessibilityIdentifier("onboarding.finish")
            Button("Back") { step = 1 }
                .font(.fun(.headline))
                .frame(maxWidth: .infinity)
        }
    }

    private func finish() {
        let name = buddyName.trimmingCharacters(in: .whitespaces)
        if addSamples && store.items.isEmpty {
            CollectionItem.samples.forEach(store.add)
        }
        store.profile = Profile(
            nickname: nickname.trimmingCharacters(in: .whitespaces),
            buddyName: name.isEmpty ? "Pip" : name,
            look: look
        )
    }
}
