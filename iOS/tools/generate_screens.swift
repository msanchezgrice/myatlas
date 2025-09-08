import Foundation
import AppKit

struct Spec { let name: String; let w: Int; let h: Int }

let specs: [Spec] = [
    Spec(name: "iphone_6.7_1", w: 1290, h: 2796),
    Spec(name: "iphone_6.5_1", w: 1242, h: 2688),
    Spec(name: "iphone_5.5_1", w: 1242, h: 2208),
    Spec(name: "ipad_12.9_1", w: 2048, h: 2732)
]

func gradientImage(width: Int, height: Int, title: String, bullets: [String]) -> NSImage {
    let size = NSSize(width: width, height: height)
    let image = NSImage(size: size)
    image.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: width, height: height)
    let start = NSColor(calibratedRed: 0.10, green: 0.36, blue: 0.84, alpha: 1)
    let end = NSColor(calibratedRed: 0.05, green: 0.18, blue: 0.42, alpha: 1)
    let gradient = NSGradient(starting: start, ending: end)!
    gradient.draw(in: rect, angle: 90)

    let titleStyle = NSMutableParagraphStyle(); titleStyle.alignment = .center
    let subtitleStyle = NSMutableParagraphStyle(); subtitleStyle.alignment = .left
    let margin: CGFloat = 60
    let titleFont = NSFont.systemFont(ofSize: CGFloat(height) * 0.08, weight: .bold)
    let subtitleFont = NSFont.systemFont(ofSize: CGFloat(height) * 0.04, weight: .semibold)

    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle: titleStyle
    ]
    let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: subtitleFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle: subtitleStyle
    ]

    (title as NSString).draw(in: NSRect(x: margin, y: CGFloat(height) - margin - titleFont.pointSize*1.4, width: CGFloat(width) - margin*2, height: titleFont.pointSize*2), withAttributes: titleAttrs)

    var y = CGFloat(height) - margin*2 - titleFont.pointSize*1.6
    for b in bullets { ("• " + b as NSString).draw(in: NSRect(x: margin, y: y, width: CGFloat(width) - margin*2, height: subtitleFont.pointSize*1.6), withAttributes: subtitleAttrs); y -= subtitleFont.pointSize*1.6 }

    image.unlockFocus()
    return image
}

let bullets = [
    "Eye alignment guide and ghost overlay",
    "Level indicator for consistent framing",
    "Background replacement on export",
    "Tagging and reminders built in"
]

let outDir = FileManager.default.currentDirectoryPath + "/screenshots"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for s in specs {
    let img = gradientImage(width: s.w, height: s.h, title: "Atlas Before & After", bullets: bullets)
    if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let data = rep.representation(using: .png, properties: [:]) {
        let path = outDir + "/\(s.name).png"
        try? data.write(to: URL(fileURLWithPath: path))
        print("Wrote \(path)")
    }
}


