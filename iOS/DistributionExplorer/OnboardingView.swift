// Introduces the app and probability distributions, then asks one education question.
import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @AppStorage("onboarding.education") private var education = ""
    @State private var showingDistributionIntroduction = false
    @State private var showingUsefulness = false
    @State private var choosingEducation = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var iconWidth = 32

    var body: some View {
        NavigationStack {
            welcome
                .navigationDestination(isPresented: $showingDistributionIntroduction) {
                    distributionIntroduction
                        .navigationDestination(isPresented: $showingUsefulness) {
                            distributionUsefulness
                                .navigationDestination(isPresented: $choosingEducation) {
                                    educationQuestion
                                }
                        }
                }
        }
    }

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 16) {
                    Image("LaunchIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190)
                        .accessibilityHidden(true)
                    Text("Distribution Explorer")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Make sense of uncertainty")
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .padding(.bottom, 8)

                feature("eye", "Understand what formulas mean",
                        "Watch random samples form a pattern and connect the maths to something you can see.")
                feature("slider.horizontal.3", "Learn by experimenting",
                        "Change a parameter and see what happens. Build a feel for spread, shape, and unlikely outcomes.")
                feature("lightbulb", "Recognize patterns in real life",
                        "Explore examples that connect distributions to measurements, waiting times, and everyday counts.")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button { showingDistributionIntroduction = true } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.continue")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
    }

    private var distributionIntroduction: some View {
        DistributionIntroductionView {
            showingUsefulness = true
        }
    }

    private var distributionUsefulness: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Why are distributions useful?")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("An average gives you one number. A distribution shows the range of possibilities.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                feature("chart.bar.xaxis", "See what’s typical",
                        "Find the completion times where most of the balls collect, and see how much task times vary.")
                feature("clock.badge.exclamationmark", "Understand the long waits",
                        "A few tasks take much longer. A distribution helps estimate how often those delays might happen.")
                feature("calendar", "Make better plans",
                        "Allow time for variation, rather than expecting every task to finish in the average time.")

                Text("The same idea helps us understand measurement errors, customer arrivals, and other uncertain outcomes.")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button { choosingEducation = true } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.usefulness.continue")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var educationQuestion: some View {
        List {
            Section {
                educationChoice("Secondary school or earlier", value: "secondary")
                educationChoice("Undergraduate", value: "undergraduate")
                educationChoice("Postgraduate", value: "postgraduate")
                educationChoice("Prefer not to say", value: "undisclosed")
            } header: {
                Text("What’s your level of education?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func educationChoice(_ title: String, value: String) -> some View {
        Button {
            education = value
            onFinish()
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("onboarding.education.\(value)")
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView {}
}
