import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
        let transform = AffineTransform(scale: CGFloat(pixels) / 1024)
        (transform as NSAffineTransform).concat()
        let rect = NSRect(x: 82, y: 82, width: 860, height: 860)
        let shape = NSBezierPath(roundedRect: rect, xRadius: 194, yRadius: 194)
        NSGradient(starting: NSColor(calibratedRed: 0.48, green: 0.42, blue: 0.94, alpha: 1), ending: NSColor(calibratedRed: 0.30, green: 0.25, blue: 0.70, alpha: 1))!.draw(in: shape, angle: -90)
        NSColor.white.setStroke()
        let layers = NSBezierPath(); layers.lineWidth = 39; layers.lineJoinStyle = .round; layers.lineCapStyle = .round
        layers.move(to: NSPoint(x: 282, y: 618)); layers.line(to: NSPoint(x: 512, y: 744)); layers.line(to: NSPoint(x: 742, y: 618)); layers.line(to: NSPoint(x: 512, y: 492)); layers.close()
        for y in [472.0, 326.0] { layers.move(to: NSPoint(x: 282, y: y)); layers.line(to: NSPoint(x: 512, y: y - 126)); layers.line(to: NSPoint(x: 742, y: y)) }
        layers.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(filename))
    }
}
