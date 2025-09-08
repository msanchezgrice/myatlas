import Foundation
import UIKit
import Vision

final class BackgroundReplaceService {
    /// Replaces background with a solid color using person segmentation.
    func replaceBackground(of image: UIImage, with color: UIColor = .white) -> UIImage {
        guard let cg = image.cgImage else { return image }
        if #available(iOS 15.0, *) {
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
            do {
                try handler.perform([request])
                if let mask = (request.results?.first as? VNPixelBufferObservation)?.pixelBuffer {
                    return composited(image: image, mask: mask, backgroundColor: color)
                }
            } catch { }
        }
        return image
    }

    private func composited(image: UIImage, mask: CVPixelBuffer, backgroundColor: UIColor) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        // Background
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        // Foreground with mask
        let ciImage = CIImage(image: image) ?? CIImage(cgImage: image.cgImage!)
        let ciMask = CIImage(cvPixelBuffer: mask)
        let composited = ciImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(color: CIColor(color: backgroundColor)).cropped(to: ciImage.extent),
            kCIInputMaskImageKey: ciMask
        ])
        let ciCtx = CIContext(options: nil)
        if let out = ciCtx.createCGImage(composited, from: composited.extent) {
            UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation).draw(in: CGRect(origin: .zero, size: size))
        } else {
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? image
    }
}


