import AppKit

enum MenuBarIcon {
    static func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            NSColor.black.setFill()
            let pixelSize = floor(min(rect.width, rect.height) / 18.0)
            let originX = rect.midX - pixelSize * 8.0
            let originY = rect.midY - pixelSize * 8.0

            for row in 0..<pixels.count {
                for column in 0..<pixels[row].count where pixels[row][column] {
                    let x = originX + CGFloat(column) * pixelSize
                    let y = originY + CGFloat(15 - row) * pixelSize
                    NSRect(x: x, y: y, width: pixelSize, height: pixelSize).fill()
                }
            }

            return true
        }

        image.isTemplate = true
        image.accessibilityDescription = "HealthyVibe"
        return image
    }

    private static let pixels: [[Bool]] = [
        row("   #######      "),
        row(" ##       ##    "),
        row("#  #######  #   "),
        row("# ######### ### "),
        row("# #########    #"),
        row("# ######### #  #"),
        row("#  #######  ## #"),
        row("#           #  #"),
        row("#              #"),
        row("#             # "),
        row("#           ##  "),
        row(" #         #    "),
        row(" #         #    "),
        row("  #       #     "),
        row("   #######      "),
        row("                ")
    ]

    private static func row(_ value: String) -> [Bool] {
        value.map { $0 == "#" }
    }
}
