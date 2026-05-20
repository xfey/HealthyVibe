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

            VStack(spacing: 5) {
                aboutLink("GitHub 仓库", path: "")
                aboutLink("医学声明", path: "blob/main/PRD.md")
                aboutLink("开源许可", path: "blob/main/LICENSE")
            }

            Spacer(minLength: 0)

            Text("HealthyVibe 0.1.0")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(HVColor.mutedText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private func aboutLink(_ title: String, path: String) -> some View {
        Link(title, destination: githubURL(path: path))
            .buttonStyle(HVCompactButtonStyle())
    }

    private func githubURL(path: String) -> URL {
        if path.isEmpty {
            return URL(string: "https://github.com/xfey/HealthyVibe")!
        }

        return URL(string: "https://github.com/xfey/HealthyVibe/\(path)")!
    }
}
