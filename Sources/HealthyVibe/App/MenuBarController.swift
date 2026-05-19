import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let appModel: AppModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(appModel: AppModel) {
        self.appModel = appModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()
    }

    func install() {
        configureStatusItem()
        configurePopover()
    }

    func show(page: AppPage = .today) {
        appModel.selectedPage = page

        guard let button = statusItem.button else {
            AppLog.ui.error("Unable to open popover because the status item button is missing.")
            return
        }

        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKey()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            AppLog.ui.error("Unable to configure status item button.")
            return
        }

        let image = NSImage(systemSymbolName: "heart.text.square", accessibilityDescription: "HealthyVibe")
            ?? NSImage(systemSymbolName: "heart", accessibilityDescription: "HealthyVibe")
        image?.isTemplate = true

        button.image = image
        button.action = #selector(togglePopover(_:))
        button.target = self
        button.toolTip = "Vibe延寿指南"
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: LayoutMetrics.popoverWidth, height: LayoutMetrics.popoverHeight)
        popover.contentViewController = NSHostingController(
            rootView: RootPopoverView()
                .environmentObject(appModel)
        )
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show(page: appModel.selectedPage)
        }
    }
}
