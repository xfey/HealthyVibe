import AppKit
import Foundation

struct PixelLogo {
    let dark: [[Bool]]
    let light: [[Bool]]

    static func load(from path: String) throws -> PixelLogo {
        let url = URL(fileURLWithPath: path)
        guard let image = NSImage(contentsOf: url),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff)
        else {
            throw NSError(domain: "HealthyVibeIcon", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to load logo source at \(path)"
            ])
        }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        var dark = Array(repeating: Array(repeating: false, count: 16), count: 16)
        var bright = Array(repeating: Array(repeating: false, count: 16), count: 16)

        for row in 0..<16 {
            for column in 0..<16 {
                let x = min(width - 1, column * width / 16 + width / 32)
                let y = min(height - 1, row * height / 16 + height / 32)
                let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) ?? .white
                let luminance = 0.2126 * color.redComponent
                    + 0.7152 * color.greenComponent
                    + 0.0722 * color.blueComponent
                dark[row][column] = luminance < 0.72
                bright[row][column] = !dark[row][column]
            }
        }

        var background = Array(repeating: Array(repeating: false, count: 16), count: 16)
        var queue: [(Int, Int)] = []

        func enqueue(_ row: Int, _ column: Int) {
            guard row >= 0, row < 16, column >= 0, column < 16 else { return }
            guard bright[row][column], !background[row][column] else { return }
            background[row][column] = true
            queue.append((row, column))
        }

        for index in 0..<16 {
            enqueue(0, index)
            enqueue(15, index)
            enqueue(index, 0)
            enqueue(index, 15)
        }

        var head = 0
        while head < queue.count {
            let (row, column) = queue[head]
            head += 1
            enqueue(row - 1, column)
            enqueue(row + 1, column)
            enqueue(row, column - 1)
            enqueue(row, column + 1)
        }

        var light = Array(repeating: Array(repeating: false, count: 16), count: 16)
        for row in 0..<16 {
            for column in 0..<16 {
                light[row][column] = bright[row][column] && !background[row][column]
            }
        }

        return PixelLogo(dark: dark, light: light)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourcePath = CommandLine.arguments.dropFirst().first ?? root.appendingPathComponent("logo.jpg").path
let resourcesURL = root.appendingPathComponent("Resources", isDirectory: true)
let buildURL = root.appendingPathComponent(".build", isDirectory: true)
let iconsetURL = buildURL.appendingPathComponent("HealthyVibe.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let logo = try PixelLogo.load(from: sourcePath)
let darkColor = NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.11, alpha: 1.0)
let lightColor = NSColor(calibratedRed: 1.00, green: 0.88, blue: 0.74, alpha: 1.0)
let baseColor = NSColor(calibratedRed: 1.00, green: 0.99, blue: 0.96, alpha: 1.0)
let strokeColor = NSColor(calibratedRed: 0.90, green: 0.45, blue: 0.16, alpha: 0.22)
let orangeColor = NSColor(calibratedRed: 0.90, green: 0.45, blue: 0.16, alpha: 1.0)

func withBitmap(width: Int, height: Int, draw: (NSRect) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    context.imageInterpolation = .none
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    draw(NSRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func withBitmap(size: Int, draw: (NSRect) -> Void) -> NSBitmapImageRep {
    withBitmap(width: size, height: size, draw: draw)
}

func writePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "HealthyVibeIcon", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Unable to encode PNG at \(url.path)"
        ])
    }
    try data.write(to: url, options: .atomic)
}

func drawPixelLogo(in rect: NSRect, includeLight: Bool) {
    let pixelSize = floor(min(rect.width, rect.height) / 16.0)
    let width = pixelSize * 16.0
    let height = pixelSize * 16.0
    let originX = rect.midX - width / 2.0
    let originY = rect.midY - height / 2.0

    for row in 0..<16 {
        for column in 0..<16 {
            if logo.dark[row][column] {
                darkColor.setFill()
            } else if includeLight && logo.light[row][column] {
                lightColor.setFill()
            } else {
                continue
            }

            let x = originX + CGFloat(column) * pixelSize
            let y = originY + CGFloat(15 - row) * pixelSize
            NSRect(x: x, y: y, width: pixelSize, height: pixelSize).fill()
        }
    }
}

func drawAppIcon(size: Int) -> NSBitmapImageRep {
    withBitmap(size: size) { canvas in
        let scale = CGFloat(size) / 1024.0
        let baseRect = NSRect(x: 100 * scale, y: 104 * scale, width: 824 * scale, height: 824 * scale)
        let radius = 184 * scale

        NSGraphicsContext.current?.cgContext.setShadow(
            offset: CGSize(width: 0, height: -18 * scale),
            blur: 34 * scale,
            color: NSColor(calibratedWhite: 0, alpha: 0.16).cgColor
        )
        baseColor.setFill()
        NSBezierPath(roundedRect: baseRect, xRadius: radius, yRadius: radius).fill()
        NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

        strokeColor.setStroke()
        let stroke = NSBezierPath(roundedRect: baseRect.insetBy(dx: 8 * scale, dy: 8 * scale), xRadius: radius - 8 * scale, yRadius: radius - 8 * scale)
        stroke.lineWidth = max(1, 6 * scale)
        stroke.stroke()

        let logoSize = 490 * scale
        let logoRect = NSRect(
            x: canvas.midX - logoSize / 2.0 + 24 * scale,
            y: canvas.midY - logoSize / 2.0 - 26 * scale,
            width: logoSize,
            height: logoSize
        )
        drawPixelLogo(in: logoRect, includeLight: true)
    }
}

func drawMenuBarTemplate(size: Int) -> NSBitmapImageRep {
    withBitmap(size: size) { canvas in
        NSColor.black.setFill()
        let logoRect = canvas.insetBy(dx: CGFloat(size) * 0.055, dy: CGFloat(size) * 0.055)
        let pixelSize = floor(min(logoRect.width, logoRect.height) / 16.0)
        let width = pixelSize * 16.0
        let height = pixelSize * 16.0
        let originX = canvas.midX - width / 2.0
        let originY = canvas.midY - height / 2.0

        for row in 0..<16 {
            for column in 0..<16 where logo.dark[row][column] {
                let x = originX + CGFloat(column) * pixelSize
                let y = originY + CGFloat(15 - row) * pixelSize
                NSRect(x: x, y: y, width: pixelSize, height: pixelSize).fill()
            }
        }
    }
}

func drawMenuBarPreview() -> NSBitmapImageRep {
    withBitmap(width: 640, height: 320) { canvas in
        NSColor(calibratedRed: 0.94, green: 0.93, blue: 0.90, alpha: 1.0).setFill()
        canvas.fill()

        let barWidth: CGFloat = 480
        let barHeight: CGFloat = 64
        let barX = (canvas.width - barWidth) / 2.0
        let lightBar = NSRect(x: barX, y: 192, width: barWidth, height: barHeight)
        let darkBar = NSRect(x: barX, y: 64, width: barWidth, height: barHeight)

        NSColor.white.setFill()
        NSBezierPath(roundedRect: lightBar, xRadius: 24, yRadius: 24).fill()
        NSColor(calibratedWhite: 0.10, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: darkBar, xRadius: 24, yRadius: 24).fill()

        func drawTemplate(in bar: NSRect, color: NSColor) {
            color.setFill()
            let iconRect = NSRect(x: bar.midX - 18, y: bar.midY - 18, width: 36, height: 36)
            let pixelSize = floor(iconRect.width / 18.0)
            let originX = iconRect.midX - pixelSize * 8.0
            let originY = iconRect.midY - pixelSize * 8.0

            for row in 0..<16 {
                for column in 0..<16 where logo.dark[row][column] {
                    let x = originX + CGFloat(column) * pixelSize
                    let y = originY + CGFloat(15 - row) * pixelSize
                    NSRect(x: x, y: y, width: pixelSize, height: pixelSize).fill()
                }
            }
        }

        drawTemplate(in: lightBar, color: .black)
        drawTemplate(in: darkBar, color: .white)
    }
}

try writePNG(drawMenuBarTemplate(size: 36), to: resourcesURL.appendingPathComponent("HealthyVibeMenuBarTemplate.png"))
try writePNG(drawMenuBarPreview(), to: resourcesURL.appendingPathComponent("HealthyVibeMenuBarTemplatePreview.png"))
try writePNG(drawAppIcon(size: 1024), to: resourcesURL.appendingPathComponent("HealthyVibeIconPreview.png"))

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    try writePNG(drawAppIcon(size: size), to: iconsetURL.appendingPathComponent(name))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = [
    "-c", "icns",
    "-o", resourcesURL.appendingPathComponent("HealthyVibe.icns").path,
    iconsetURL.path
]
try iconutil.run()
iconutil.waitUntilExit()

if iconutil.terminationStatus != 0 {
    throw NSError(domain: "HealthyVibeIcon", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "iconutil failed with status \(iconutil.terminationStatus)"
    ])
}

print("Generated Resources/HealthyVibe.icns")
print("Generated Resources/HealthyVibeIconPreview.png")
print("Generated Resources/HealthyVibeMenuBarTemplate.png")
