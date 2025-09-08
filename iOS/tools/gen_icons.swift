import Foundation
import AppKit

struct IconSpec: Codable {
    var idiom: String
    var size: String
    var scale: String
    var filename: String?
}

struct Contents: Codable {
    var images: [IconSpec]
    var info: [String: AnyCodable]
}

struct AnyCodable: Codable {}

let fm = FileManager.default
let projectDir = fm.currentDirectoryPath
let appIconDir = projectDir + "/AtlasBeforeAfter/Assets.xcassets/AppIcon.appiconset"
let jsonPath = appIconDir + "/Contents.json"

let specs: [(idiom: String, size: String, scale: String, filename: String, px: Int)] = [
    ("iphone", "60x60", "2x", "icon-60@2x.png", 120),
    ("iphone", "60x60", "3x", "icon-60@3x.png", 180),
    ("ipad", "76x76", "2x", "icon-76@2x.png", 152),
    ("ipad", "83.5x83.5", "2x", "icon-83.5@2x.png", 167),
    ("ios-marketing", "1024x1024", "1x", "icon-1024.png", 1024),
]

func generatePNG(size: Int, to path: String) throws {
    if fm.fileExists(atPath: path) {
        try? fm.removeItem(atPath: path)
    }
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
    NSGraphicsContext.current = ctx
    NSColor(calibratedRed: 0.10, green: 0.36, blue: 0.84, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
    let text = "A"
    let style = NSMutableParagraphStyle(); style.alignment = .center
    let fontSize = CGFloat(size) * 0.6
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: style
    ]
    let rect = NSRect(x: 0, y: (CGFloat(size) - fontSize)/2 - fontSize*0.1, width: CGFloat(size), height: fontSize*1.2)
    (text as NSString).draw(in: rect, withAttributes: attributes)
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try data.write(to: URL(fileURLWithPath: path))
}

func loadContents() -> [String: Any] {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
    return json
}

func saveContents(_ dict: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
    try data.write(to: URL(fileURLWithPath: jsonPath))
}

var contents = loadContents()
var images = contents["images"] as? [[String: Any]] ?? []

for s in specs {
    let filePath = appIconDir + "/" + s.filename
    try? generatePNG(size: s.px, to: filePath)
    if let index = images.firstIndex(where: { ($0["idiom"] as? String) == s.idiom && ($0["size"] as? String) == s.size && ($0["scale"] as? String) == s.scale }) {
        images[index]["filename"] = s.filename
    } else {
        images.append(["idiom": s.idiom, "size": s.size, "scale": s.scale, "filename": s.filename])
    }
}

contents["images"] = images
if contents["info"] == nil { contents["info"] = ["version": 1, "author": "xcode"] }
try? saveContents(contents)

print("Generated/updated app icons at \(appIconDir)")


