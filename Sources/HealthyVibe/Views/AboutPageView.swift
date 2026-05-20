import SwiftUI

struct AboutPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("xfey/HealthyVibe")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HVColor.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            Text("碳基生物，咱们一起变得更健康吧")
                .font(.system(size: 9))
                .foregroundStyle(HVColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 5),
                    GridItem(.flexible(), spacing: 5)
                ],
                spacing: 5
            ) {
                aboutLink("GitHub 仓库", destination: githubURL(path: ""))
                aboutLink("医学声明", destination: githubURL(path: "blob/main/PRD.md"))
                aboutLink("开源许可", destination: githubURL(path: "blob/main/LICENSE"))
                aboutLink("延寿指南", destination: URL(string: "https://github.com/geekan/HowToLiveLonger")!)
            }

            Spacer(minLength: 0)

            Text("HealthyVibe \(appVersion)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(HVColor.mutedText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private func aboutLink(_ title: String, destination: URL) -> some View {
        Link(title, destination: destination)
            .buttonStyle(HVCompactButtonStyle())
    }

    private func githubURL(path: String) -> URL {
        if path.isEmpty {
            return URL(string: "https://github.com/xfey/HealthyVibe")!
        }

        return URL(string: "https://github.com/xfey/HealthyVibe/\(path)")!
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1"
    }
}
