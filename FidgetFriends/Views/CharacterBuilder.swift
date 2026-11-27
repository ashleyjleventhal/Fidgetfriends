import SwiftUI

/// Pick-and-mix builder for the kid's squishy sidekick. Used at setup and on the My character tab.
struct CharacterBuilder: View {
    @Binding var look: CharacterLook
    @Binding var buddyName: String
    @State private var bounce = false

    var body: some View {
        VStack(spacing: 20) {
            preview
            optionRow("Shape", CritterSpecies.characterChoices, selected: look.species, id: "species") { species in
                CritterView(species: species, color: look.color, eyes: .dots, mouth: .smile, showsShadow: false)
            } label: { $0.label } set: { look.species = $0 }

            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Color")
                FlowLayout(spacing: 12) {
                    ForEach(CritterColor.allCases) { color in
                        Button { pick { look.color = color } } label: {
                            Circle()
                                .fill(LinearGradient(colors: color.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 50, height: 50)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                                .overlay(Circle().strokeBorder(look.color == color ? Palette.grape : .clear, lineWidth: 4).padding(-5))
                                .overlay { if look.color == color { Image(systemName: "checkmark").font(.headline.weight(.black)).foregroundStyle(.white) } }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.label)
                        .accessibilityAddTraits(look.color == color ? .isSelected : [])
                        .accessibilityIdentifier("builder.color.\(color.rawValue)")
                    }
                }
            }

            optionRow("Eyes", EyeStyle.allCases, selected: look.eyes, id: "eyes") { eyes in
                CritterView(species: .blob, color: look.color, eyes: eyes, mouth: look.mouth, showsShadow: false)
            } label: { $0.label } set: { look.eyes = $0 }

            optionRow("Mouth", MouthStyle.allCases, selected: look.mouth, id: "mouth") { mouth in
                CritterView(species: .blob, color: look.color, eyes: look.eyes, mouth: mouth, showsShadow: false)
            } label: { $0.label } set: { look.mouth = $0 }

            optionRow("Accessory", Accessory.allCases, selected: look.accessory, id: "accessory") { accessory in
                CritterView(species: look.species, color: look.color, eyes: look.eyes, mouth: look.mouth, accessory: accessory, showsShadow: false)
            } label: { $0.label } set: { look.accessory = $0 }

            Toggle(isOn: Binding(get: { look.cheeks }, set: { value in pick { look.cheeks = value } })) {
                Text("Rosy cheeks").font(.fun(.title3, weight: .heavy)).foregroundStyle(Palette.ink)
            }
            .tint(Palette.coral)
            .padding(16)
            .stickerCard()
            .accessibilityIdentifier("builder.cheeks")

            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Name your buddy", trailing: "Optional")
                FunTextField(placeholder: Profile.defaultBuddyName, text: $buddyName, maxLength: 16)
                    .accessibilityIdentifier("builder.buddyName")
            }
        }
    }

    private var preview: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white, look.color.pastel], center: .center, startRadius: 10, endRadius: 140))
                .frame(width: 230, height: 230)
            SparkleSprinkles(color: Palette.coral).frame(width: 270, height: 250)
            CritterView(look: look)
                .frame(width: 190, height: 190)
                .scaleEffect(bounce ? 1.08 : 1)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomTrailing) {
            Button { pick { look = .random() } } label: {
                Label("Surprise me", systemImage: "dice.fill")
            }
            .buttonStyle(.chunky(Palette.coral, shadow: Palette.coralDeep, fullWidth: false))
            .controlSize(.small)
            .accessibilityIdentifier("builder.surprise")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your buddy preview")
    }

    private func pick(_ change: () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            change()
            bounce = true
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) { bounce = false }
    }

    private func optionRow<Option: Identifiable & Equatable & RawRepresentable, Preview: View>(
        _ title: String, _ options: [Option], selected: Option, id: String,
        @ViewBuilder preview: @escaping (Option) -> Preview,
        label: @escaping (Option) -> String, set: @escaping (Option) -> Void
    ) -> some View where Option.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(options) { option in
                        Button { pick { set(option) } } label: {
                            VStack(spacing: 4) {
                                preview(option).frame(width: 66, height: 66)
                                Text(label(option)).font(.fun(.caption)).foregroundStyle(Palette.ink).lineLimit(1)
                            }
                            .frame(width: 88)
                            .padding(.vertical, 8)
                            .stickerCard(radius: 20, selected: option == selected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(title): \(label(option))")
                        .accessibilityAddTraits(option == selected ? [.isButton, .isSelected] : .isButton)
                        .accessibilityIdentifier("builder.\(id).\(option.rawValue)")
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
    }
}
