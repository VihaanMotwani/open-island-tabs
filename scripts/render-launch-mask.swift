#!/usr/bin/swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 9,
      let canvasWidth = Double(CommandLine.arguments[1]),
      let canvasHeight = Double(CommandLine.arguments[2]),
      let rectX = Double(CommandLine.arguments[3]),
      let rectY = Double(CommandLine.arguments[4]),
      let rectWidth = Double(CommandLine.arguments[5]),
      let rectHeight = Double(CommandLine.arguments[6]),
      let cornerRadius = Double(CommandLine.arguments[7]) else {
    fputs(
        "Usage: render-launch-mask.swift <canvas-width> <canvas-height> <x> <y> <width> <height> <radius> <output.png>\n",
        stderr
    )
    exit(1)
}

let outputPath = CommandLine.arguments[8]
let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)
let canvas = NSImage(size: canvasSize)
canvas.lockFocusFlipped(true)

NSColor.black.setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let islandRect = NSRect(
    x: rectX,
    y: rectY,
    width: rectWidth,
    height: rectHeight
)
NSColor.white.setFill()
NSBezierPath(
    roundedRect: islandRect,
    xRadius: cornerRadius,
    yRadius: cornerRadius
).fill()

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode launch mask\n", stderr)
    exit(2)
}

try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
