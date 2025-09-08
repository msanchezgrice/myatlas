import Foundation
import UIKit
import Vision

final class VisionStandardizer {
    struct Options {
        var targetInterPupilDistance: CGFloat = 200 // pixels
        var outputSize: CGSize = CGSize(width: 1024, height: 1024)
        var backgroundColor: UIColor = .black
    }

    private let options: Options
    init(options: Options = Options()) {
        self.options = options
    }

    func standardize(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(from: image.imageOrientation))
        do {
            try handler.perform([request])
        } catch {
            return image
        }
        guard let face = (request.results as? [VNFaceObservation])?.first,
              let landmarks = face.landmarks,
              let left = landmarks.leftPupil?.normalizedPoints.first ?? landmarks.leftEye?.normalizedPoints.first,
              let right = landmarks.rightPupil?.normalizedPoints.first ?? landmarks.rightEye?.normalizedPoints.first else { return image }

        // Convert normalized landmark points to image coordinates within face bounding box
        let bounding = face.boundingBox
        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)
        let faceRect = CGRect(x: bounding.minX * imgW,
                               y: (1 - bounding.maxY) * imgH,
                               width: bounding.width * imgW,
                               height: bounding.height * imgH)

        let leftPt = CGPoint(x: faceRect.minX + CGFloat(left.x) * faceRect.width,
                              y: faceRect.minY + CGFloat(1 - left.y) * faceRect.height)
        let rightPt = CGPoint(x: faceRect.minX + CGFloat(right.x) * faceRect.width,
                               y: faceRect.minY + CGFloat(1 - right.y) * faceRect.height)

        // Compute rotation angle to make eyes horizontal
        let angle = atan2(rightPt.y - leftPt.y, rightPt.x - leftPt.x)
        let targetAngle: CGFloat = 0
        let rotation = targetAngle - angle

        // Rotate image around mid-point of eyes
        let eyesCenter = CGPoint(x: (leftPt.x + rightPt.x) / 2, y: (leftPt.y + rightPt.y) / 2)
        guard let rotated = rotate(image: image, angle: rotation, around: eyesCenter, background: options.backgroundColor) else {
            return image
        }

        // Recompute eyes points after rotation by applying transform
        let transform = CGAffineTransform(translationX: -eyesCenter.x, y: -eyesCenter.y)
            .rotated(by: rotation)
            .translatedBy(x: eyesCenter.x, y: eyesCenter.y)
        let leftR = leftPt.applying(transform)
        let rightR = rightPt.applying(transform)

        // Scale so that inter-pupil distance matches target
        let ipdRaw = hypot(rightR.x - leftR.x, rightR.y - leftR.y)
        let ipd = ipdRaw.isFinite && ipdRaw > 0 ? ipdRaw : 1
        let scaleRaw = options.targetInterPupilDistance / ipd
        let scale = scaleRaw.isFinite && scaleRaw > 0.001 && scaleRaw < 1000 ? scaleRaw : 1
        let scaledWidth = max(1, rotated.size.width * scale)
        let scaledHeight = max(1, rotated.size.height * scale)
        let scaledSize = CGSize(width: scaledWidth, height: scaledHeight)
        guard let scaled = resize(image: rotated, size: scaledSize) else { return rotated }

        // Crop centered on eyes to the output size
        let eyesCenterScaled = CGPoint(x: (leftR.x + rightR.x) / 2 * scale, y: (leftR.y + rightR.y) / 2 * scale)
        let cropOrigin = CGPoint(x: eyesCenterScaled.x - options.outputSize.width / 2,
                                  y: eyesCenterScaled.y - options.outputSize.height * 0.45) // bias slightly upward
        let rawCropRect = CGRect(origin: cropOrigin, size: options.outputSize)
        // Clamp crop to image bounds
        let maxX = scaled.size.width
        let maxY = scaled.size.height
        var cropRect = rawCropRect
        if !rawCropRect.origin.x.isFinite || !rawCropRect.origin.y.isFinite {
            cropRect.origin = .zero
        }
        cropRect.origin.x = min(max(0, cropRect.origin.x), maxX - 1)
        cropRect.origin.y = min(max(0, cropRect.origin.y), maxY - 1)
        cropRect.size.width = min(options.outputSize.width, maxX - cropRect.origin.x)
        cropRect.size.height = min(options.outputSize.height, maxY - cropRect.origin.y)
        if cropRect.size.width < 1 || cropRect.size.height < 1 {
            return scaled
        }
        return crop(image: scaled, rect: cropRect) ?? scaled
    }

    // MARK: - Helpers
    private func rotate(image: UIImage, angle: CGFloat, around pivot: CGPoint, background: UIColor) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.setFillColor(background.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.translateBy(x: pivot.x, y: pivot.y)
        ctx.rotate(by: angle)
        ctx.translateBy(x: -pivot.x, y: -pivot.y)
        UIImage(cgImage: cg).draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func resize(image: UIImage, size: CGSize) -> UIImage? {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func crop(image: UIImage, rect: CGRect) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let scale = image.scale
        let safeMinX = max(0, rect.minX)
        let safeMinY = max(0, rect.minY)
        let safeWidth = min(rect.width, image.size.width - safeMinX)
        let safeHeight = min(rect.height, image.size.height - safeMinY)
        guard safeWidth.isFinite, safeHeight.isFinite, safeWidth > 0, safeHeight > 0 else { return nil }
        let r = CGRect(x: safeMinX * scale,
                        y: safeMinY * scale,
                        width: safeWidth * scale,
                        height: safeHeight * scale)
        guard let cropped = cg.cropping(to: r) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: image.imageOrientation)
    }

    private func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
