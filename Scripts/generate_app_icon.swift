#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let buildIconset = root
    .appendingPathComponent(".build", isDirectory: true)
    .appendingPathComponent("HealthyVibe.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: buildIconset)
try FileManager.default.createDirectory(at: buildIconset, withIntermediateDirectories: true)

let iconFiles: [(String, Int)] = [
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

for (name, size) in iconFiles {
    let image = makeIcon(pixelSize: size)
    try writePNG(image, to: buildIconset.appendingPathComponent(name))
}

try writePNG(makeIcon(pixelSize: 1024), to: resources.appendingPathComponent("HealthyVibeIconPreview.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = [
    "-c", "icns",
    buildIconset.path,
    "-o", resources.appendingPathComponent("HealthyVibe.icns").path
]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    throw NSError(
        domain: "HealthyVibeIcon",
        code: Int(iconutil.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: "iconutil failed."]
    )
}

print("Generated Resources/HealthyVibe.icns")
print("Generated Resources/HealthyVibeIconPreview.png")

private func makeIcon(pixelSize: Int) -> CGImage {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: pixelSize * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    let scale = CGFloat(pixelSize) / 1024
    context.translateBy(x: 0, y: CGFloat(pixelSize))
    context.scaleBy(x: scale, y: -scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    drawBase(in: context)
    drawMark(in: context)

    return context.makeImage()!
}

private func drawBase(in context: CGContext) {
    let baseRect = CGRect(x: 102, y: 96, width: 820, height: 820)
    let basePath = CGPath(
        roundedRect: baseRect,
        cornerWidth: 184,
        cornerHeight: 184,
        transform: nil
    )

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -20),
        blur: 26,
        color: CGColor(red: 0.34, green: 0.22, blue: 0.14, alpha: 0.15)
    )
    context.addPath(basePath)
    context.setFillColor(CGColor(red: 0.99, green: 0.985, blue: 0.97, alpha: 1))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(basePath)
    context.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [
            CGColor(red: 1.0, green: 0.998, blue: 0.99, alpha: 1),
            CGColor(red: 0.975, green: 0.955, blue: 0.925, alpha: 1)
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: baseRect.midX, y: baseRect.minY),
        end: CGPoint(x: baseRect.midX, y: baseRect.maxY),
        options: []
    )
    context.restoreGState()

    context.addPath(basePath)
    context.setStrokeColor(CGColor(red: 0.86, green: 0.81, blue: 0.74, alpha: 0.72))
    context.setLineWidth(5)
    context.strokePath()
}

private func drawMark(in context: CGContext) {
    let orange = CGColor(red: 0.88, green: 0.38, blue: 0.20, alpha: 1)
    let softOrange = CGColor(red: 0.88, green: 0.38, blue: 0.20, alpha: 0.18)

    let cardRect = CGRect(x: 326, y: 318, width: 372, height: 386)
    let cardPath = CGPath(
        roundedRect: cardRect,
        cornerWidth: 92,
        cornerHeight: 92,
        transform: nil
    )

    context.addPath(cardPath)
    context.setFillColor(softOrange)
    context.fillPath()

    context.addPath(cardPath)
    context.setStrokeColor(orange)
    context.setLineWidth(38)
    context.strokePath()

    context.addPath(makeHeartPath(center: CGPoint(x: 512, y: 438), width: 154, height: 140))
    context.setFillColor(orange)
    context.fillPath()

    drawRoundedBar(in: context, rect: CGRect(x: 402, y: 538, width: 220, height: 28), color: orange)
    drawRoundedBar(in: context, rect: CGRect(x: 424, y: 596, width: 176, height: 28), color: orange)
    drawRoundedBar(in: context, rect: CGRect(x: 450, y: 654, width: 124, height: 28), color: orange)
}

private func drawRoundedBar(in context: CGContext, rect: CGRect, color: CGColor) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: rect.height / 2, cornerHeight: rect.height / 2, transform: nil))
    context.setFillColor(color)
    context.fillPath()
}

private func makeHeartPath(center: CGPoint, width: CGFloat, height: CGFloat) -> CGPath {
    var points: [CGPoint] = []
    let sampleCount = 160

    for index in 0...sampleCount {
        let t = CGFloat(index) / CGFloat(sampleCount) * CGFloat.pi * 2
        let x = 16 * pow(sin(t), 3)
        let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
        points.append(CGPoint(x: x, y: y))
    }

    let minX = points.map(\.x).min()!
    let maxX = points.map(\.x).max()!
    let minY = points.map(\.y).min()!
    let maxY = points.map(\.y).max()!

    let path = CGMutablePath()
    for (index, point) in points.enumerated() {
        let normalizedX = (point.x - minX) / (maxX - minX)
        let normalizedY = (point.y - minY) / (maxY - minY)
        let mapped = CGPoint(
            x: center.x - width / 2 + normalizedX * width,
            y: center.y - height / 2 + normalizedY * height
        )

        if index == 0 {
            path.move(to: mapped)
        } else {
            path.addLine(to: mapped)
        }
    }
    path.closeSubpath()
    return path
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "HealthyVibeIcon",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not create PNG destination."]
        )
    }

    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        throw NSError(
            domain: "HealthyVibeIcon",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Could not write PNG."]
        )
    }
}
