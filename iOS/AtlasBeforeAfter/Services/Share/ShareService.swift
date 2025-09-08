import Foundation
import UIKit

final class ShareService {
    struct Watermark {
        let provider: String
        let clinic: String
        let caseTitle: String
    }

    func watermarked(_ image: UIImage, with wm: Watermark) -> UIImage {
        let scale = image.scale
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        var base = image
        // Optional background replacement from Settings
        if UserDefaults.standard.bool(forKey: "export.replaceBackground") {
            let hex = (UserDefaults.standard.string(forKey: "export.bgColorHex") ?? "#FFFFFF").trimmingCharacters(in: .whitespaces)
            let bg = UIColor(hex: hex) ?? .white
            let replacer = BackgroundReplaceService()
            base = replacer.replaceBackground(of: image, with: bg)
        }
        base.draw(in: CGRect(origin: .zero, size: size))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let pad: CGFloat = 12
        let text = "\(wm.provider) — \(wm.clinic)\n\(wm.caseTitle)\nFor patient use only"
        let textRect = CGRect(x: pad, y: size.height - 100 - pad, width: size.width - pad * 2, height: 100)
        UIColor.black.withAlphaComponent(0.35).setFill()
        UIBezierPath(roundedRect: textRect.insetBy(dx: -8, dy: -8), cornerRadius: 8).fill()
        (text as NSString).draw(in: textRect, withAttributes: attrs)
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }

    func writeTempPNG(_ image: UIImage) -> URL? {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let url = dir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        guard let data = image.pngData() else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}

private extension UIColor {
    convenience init?(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
        let r = CGFloat((v >> 16) & 0xFF) / 255.0
        let g = CGFloat((v >> 8) & 0xFF) / 255.0
        let b = CGFloat(v & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
