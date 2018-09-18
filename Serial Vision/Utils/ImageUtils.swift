
import Foundation
import UIKit
import Vision

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func convertToGrayscale() -> UIImage {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil,
                                width: Int(UInt(self.size.width)),
                                height: Int(UInt(self.size.height)),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        context?.draw(self.cgImage!,
                      in: CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
        let imageRef: CGImage = context!.makeImage()!
        let newImage: UIImage = UIImage(cgImage: imageRef)
        return newImage
    }
    
    func insertInsets(insetWidthDimension: CGFloat, insetHeightDimension: CGFloat)
        -> UIImage {
            let adjustedImage = self.adjustColors()
            let upperLeftPoint: CGPoint = CGPoint(x: 1, y: 1)
            let lowerLeftPoint: CGPoint = CGPoint(x: 1, y: adjustedImage.size.height - 2)
            let upperRightPoint: CGPoint = CGPoint(x: adjustedImage.size.width - 2, y: 1)
            let lowerRightPoint: CGPoint = CGPoint(x: adjustedImage.size.width - 2,
                                                   y: adjustedImage.size.height - 2)
            let upperLeftColor: UIColor = adjustedImage.getPixelColor(pixel: upperLeftPoint)
            let lowerLeftColor: UIColor = adjustedImage.getPixelColor(pixel: lowerLeftPoint)
            let upperRightColor: UIColor = adjustedImage.getPixelColor(pixel: upperRightPoint)
            let lowerRightColor: UIColor = adjustedImage.getPixelColor(pixel: lowerRightPoint)
            let color =
                averageColor(fromColors: [upperLeftColor, lowerLeftColor, upperRightColor, lowerRightColor])
            let insets = UIEdgeInsets(top: insetHeightDimension,
                                      left: insetWidthDimension,
                                      bottom: insetHeightDimension,
                                      right: insetWidthDimension)
            let size = CGSize(width: adjustedImage.size.width + insets.left + insets.right,
                              height: adjustedImage.size.height + insets.top + insets.bottom)
            UIGraphicsBeginImageContextWithOptions(size, false, adjustedImage.scale)
            let origin = CGPoint(x: insets.left, y: insets.top)
            adjustedImage.draw(at: origin)
            let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return imageWithInsets!.convertTransparent(color: color)
    }
    
    func averageColor(fromColors colors: [UIColor]) -> UIColor {
        var averages = [CGFloat]()
        for i in 0..<3 {
            var total: CGFloat = 0
            var count = 0
            for j in 0..<colors.count {
                let current = colors[j]
                let value = CGFloat(current.cgColor.components![i])
                total += value
                if(value != 0) {
                    count += 1
                }
            }
            let avg = total / CGFloat(count)
            averages.append(avg)
        }
        let highestAvg = max(averages[0], averages[1], averages[2])
        return UIColor(red: highestAvg, green: highestAvg, blue: highestAvg, alpha: 1)
    }
    
    func adjustColors() -> UIImage {
        let context = CIContext(options: nil)
        if let currentFilter = CIFilter(name: "CIColorControls") {
            let beginImage = CIImage(image: self)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            currentFilter.setValue(0, forKey: kCIInputSaturationKey)
            //currentFilter.setValue(1.45, forKey: kCIInputContrastKey) //previous 1.5
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    let processedImage = UIImage(cgImage: cgimg)
                    return processedImage
                }
            }
        }
        return self
    }
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return self
        }
    }
    
    
    
    func convertTransparent(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let width = self.size.width
        let height = self.size.height
        let imageRect: CGRect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        let redValue = CGFloat(color.cgColor.components![0])
        let greenValue = CGFloat(color.cgColor.components![1])
        let blueValue = CGFloat(color.cgColor.components![2])
        let alphaValue = CGFloat(color.cgColor.components![3])
        ctx.setFillColor(red: redValue, green: greenValue, blue: blueValue, alpha: alphaValue)
        ctx.fill(imageRect)
        self.draw(in: imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func getPixelColor(pixel: CGPoint) -> UIColor {
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(pixel.y)) + Int(pixel.x)) * 4
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo + 1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo + 2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo + 3]) / CGFloat(255.0)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func crop(rectangle: VNRectangleObservation) -> UIImage? {
        var t: CGAffineTransform = CGAffineTransform.identity;
        t = t.scaledBy(x: self.size.width, y: -self.size.height);
        t = t.translatedBy(x: 0, y: -1 );
        let x = rectangle.boundingBox.applying(t).origin.x
        let y = rectangle.boundingBox.applying(t).origin.y
        let width = rectangle.boundingBox.applying(t).width
        let height = rectangle.boundingBox.applying(t).height
        let fromRect = CGRect(x: x, y: y, width: width, height: height)
        let drawImage = self.cgImage!.cropping(to: fromRect)
        if let drawImage = drawImage {
            let uiImage = UIImage(cgImage: drawImage)
            return uiImage
        }
        return nil
    }
    
    func preProcess() -> UIImage {
        let width = self.size.width
        let height = self.size.height
        let addToHeight = height / 20
        let addToWidth = ((6 * height) / 3 - width) / 20
        let imageWithInsets = self.insertInsets(insetWidthDimension: addToWidth,
                                           insetHeightDimension: addToHeight)
        let size = CGSize(width: 28, height: 28)
        let resizedImage = imageWithInsets.resize(targetSize: size)
        let grayScaleImage = resizedImage.convertToGrayscale()
        return grayScaleImage
    }
}
