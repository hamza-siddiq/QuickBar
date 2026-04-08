import AppKit

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // --- Rounded rectangle background (macOS squircle style) ---
    let inset = size * 0.08
    let bgRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = size * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Draw shadow first
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.01), blur: size * 0.03,
                  color: CGColor(colorSpace: colorSpace, components: [0.0, 0.0, 0.0, 0.35])!)
    ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0.12, 0.10, 0.30, 1.0])!)
    ctx.addPath(bgPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Background gradient: deep navy to rich purple
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let bgColors = [
        CGColor(colorSpace: colorSpace, components: [0.08, 0.10, 0.32, 1.0])!,
        CGColor(colorSpace: colorSpace, components: [0.22, 0.08, 0.50, 1.0])!,
        CGColor(colorSpace: colorSpace, components: [0.38, 0.14, 0.65, 1.0])!
    ] as CFArray

    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(bgGradient,
                              start: CGPoint(x: bgRect.minX, y: bgRect.maxY),
                              end: CGPoint(x: bgRect.maxX, y: bgRect.minY),
                              options: [])
    }

    // Subtle top highlight
    let highlightColors = [
        CGColor(colorSpace: colorSpace, components: [1.0, 1.0, 1.0, 0.10])!,
        CGColor(colorSpace: colorSpace, components: [1.0, 1.0, 1.0, 0.0])!
    ] as CFArray
    if let highlightGrad = CGGradient(colorsSpace: colorSpace, colors: highlightColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(highlightGrad,
                              start: CGPoint(x: bgRect.midX, y: bgRect.maxY),
                              end: CGPoint(x: bgRect.midX, y: bgRect.midY + bgRect.height * 0.1),
                              options: [])
    }
    ctx.restoreGState()

    // --- 2x2 Grid of rounded squares (centered) ---
    let gridSize = size * 0.38
    let gap = size * 0.045
    let cellSize = (gridSize - gap) / 2.0
    let cellRadius = cellSize * 0.25

    let gridX = (size - gridSize) / 2.0
    let gridY = (size - gridSize) / 2.0

    let positions: [(CGFloat, CGFloat)] = [
        (gridX, gridY + cellSize + gap),                // top-left
        (gridX + cellSize + gap, gridY + cellSize + gap), // top-right
        (gridX, gridY),                                  // bottom-left
        (gridX + cellSize + gap, gridY),                 // bottom-right
    ]

    // Cell colors: each cell gets a slightly different tint for personality
    let cellColors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (1.0, 1.0, 1.0, 0.95),   // white
        (0.75, 0.85, 1.0, 0.85), // light blue
        (0.85, 0.75, 1.0, 0.85), // light purple
        (0.65, 0.80, 1.0, 0.80), // blue
    ]

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    for (i, (cx, cy)) in positions.enumerated() {
        let cellRect = CGRect(x: cx, y: cy, width: cellSize, height: cellSize)
        let cellPath = CGPath(roundedRect: cellRect, cornerWidth: cellRadius, cornerHeight: cellRadius, transform: nil)

        // Soft glow behind each cell
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: size * 0.025,
                      color: CGColor(colorSpace: colorSpace, components: [0.7, 0.8, 1.0, 0.3])!)
        let (r, g, b, a) = cellColors[i]
        ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [r, g, b, a])!)
        ctx.addPath(cellPath)
        ctx.fillPath()
        ctx.restoreGState()

        // Cell fill with subtle gradient
        ctx.saveGState()
        ctx.addPath(cellPath)
        ctx.clip()

        let topColor = CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
        let botColor = CGColor(colorSpace: colorSpace, components: [r * 0.9, g * 0.9, b * 0.95, a * 0.9])!
        if let cellGrad = CGGradient(colorsSpace: colorSpace, colors: [topColor, botColor] as CFArray, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(cellGrad,
                                  start: CGPoint(x: cellRect.midX, y: cellRect.maxY),
                                  end: CGPoint(x: cellRect.midX, y: cellRect.minY),
                                  options: [])
        }
        ctx.restoreGState()
    }

    ctx.restoreGState()

    image.unlockFocus()
    return image
}

// Generate icon set
let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512]
let iconsetDir = "icon.iconset"

let fm = FileManager.default
if let files = try? fm.contentsOfDirectory(atPath: iconsetDir) {
    for file in files {
        try? fm.removeItem(atPath: "\(iconsetDir)/\(file)")
    }
}

for size in sizes {
    let image = createIcon(size: size)
    let tiff = image.tiffRepresentation!
    let rep = NSBitmapImageRep(data: tiff)!
    let normalName = "\(iconsetDir)/icon_\(Int(size))x\(Int(size)).png"
    let normalData = rep.representation(using: .png, properties: [:])!
    try! normalData.write(to: URL(fileURLWithPath: normalName))

    if size <= 256 {
        let retinaImage = createIcon(size: size * 2)
        let retinaTiff = retinaImage.tiffRepresentation!
        let retinaRep = NSBitmapImageRep(data: retinaTiff)!
        let retinaName = "\(iconsetDir)/icon_\(Int(size))x\(Int(size))@2x.png"
        let retinaData = retinaRep.representation(using: .png, properties: [:])!
        try! retinaData.write(to: URL(fileURLWithPath: retinaName))
    }
}

let bigImage = createIcon(size: 1024)
let bigTiff = bigImage.tiffRepresentation!
let bigRep = NSBitmapImageRep(data: bigTiff)!
let bigData = bigRep.representation(using: .png, properties: [:])!
try! bigData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_512x512@2x.png"))

print("Icon set generated successfully")
