#!/usr/bin/swift

import AppKit
import Foundation

private enum CaptionStyle: String {
    case hook
    case supporting
    case end

    var fontSize: CGFloat {
        switch self {
        case .hook, .end: 34
        case .supporting: 30
        }
    }

    var fontWeight: NSFont.Weight {
        .medium
    }

    var foregroundColor: NSColor {
        switch self {
        case .end: NSColor(calibratedRed: 0.93, green: 0.91, blue: 0.84, alpha: 1)
        case .hook, .supporting: NSColor(calibratedWhite: 0.96, alpha: 1)
        }
    }
}

private let canvasSize = NSSize(width: 1920, height: 1080)

guard CommandLine.arguments.count == 4,
      let style = CaptionStyle(rawValue: CommandLine.arguments[1]) else {
    fputs("Usage: render-launch-caption.swift <hook|supporting|end> <text> <output.png>\n", stderr)
    exit(1)
}

let text = CommandLine.arguments[2]
let outputPath = CommandLine.arguments[3]
let canvas = NSImage(size: canvasSize)
canvas.lockFocusFlipped(true)

let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: style.fontSize, weight: style.fontWeight),
    .foregroundColor: style.foregroundColor,
    .kern: -0.2,
]
let textSize = (text as NSString).size(withAttributes: textAttributes)
let capsuleSize = NSSize(width: textSize.width + 72, height: 66)
let capsuleRect = NSRect(
    x: (canvasSize.width - capsuleSize.width) / 2,
    y: 954,
    width: capsuleSize.width,
    height: capsuleSize.height
)
let capsule = NSBezierPath(roundedRect: capsuleRect, xRadius: 22, yRadius: 22)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
shadow.shadowBlurRadius = 18
shadow.shadowOffset = NSSize(width: 0, height: 5)
shadow.set()
NSColor(calibratedWhite: 0.035, alpha: 0.82).setFill()
capsule.fill()
NSGraphicsContext.restoreGraphicsState()

NSColor.white.withAlphaComponent(0.11).setStroke()
capsule.lineWidth = 1
capsule.stroke()

let textOrigin = NSPoint(
    x: (canvasSize.width - textSize.width) / 2,
    y: capsuleRect.minY + (capsuleRect.height - textSize.height) / 2 - 1
)
(text as NSString).draw(at: textOrigin, withAttributes: textAttributes)
canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode launch caption\n", stderr)
    exit(2)
}

try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
