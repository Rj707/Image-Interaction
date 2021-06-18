//
//  ViewController.swift
//  testImage
//
//  Created by Shoaib Hassan on 21/04/2021.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController
{
    @IBOutlet weak var zoomView: UIView!
    
    @IBOutlet weak var fakeImageView: UIImageView!
    @IBOutlet weak var realImageView: UIImageView!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedColors = [String:Bool]()

    struct RGBA32: Equatable
    {
        private var color: UInt32

        var redComponent: UInt8
        {
            return UInt8((color >> 24) & 255)
        }

        var greenComponent: UInt8
        {
            return UInt8((color >> 16) & 255)
        }

        var blueComponent: UInt8
        {
            return UInt8((color >> 8) & 255)
        }

        var alphaComponent: UInt8
        {
            return UInt8((color >> 0) & 255)
        }

        init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
        {
            let red   = UInt32(red)
            let green = UInt32(green)
            let blue  = UInt32(blue)
            let alpha = UInt32(alpha)
            color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
        }

        static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
        static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
        static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
        static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
        static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
        static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
        static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
        static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
        
        static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

        static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool
        {
            return lhs.color == rhs.color
        }
    }
    
    //MARK:- Implementation
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        prepareImageViewTapGesture()
        configureScrollView()
    }
    
    func configureScrollView()
    {
        scrollView.delegate = self
        
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.flashScrollIndicators()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
    }
    
    //MARK:- TapGesture
    
    func prepareImageViewTapGesture()
    {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        fakeImageView.isUserInteractionEnabled = true
        fakeImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let locationOfTouch = tapGestureRecognizer.location(in: fakeImageView)
        
        let resultColor = self.getPixelColorAtPoint(point: locationOfTouch, sourceView: realImageView)
        self.navigationController?.navigationBar.barTintColor = resultColor
        
        switch resultColor.hexStringFromColor()
        {
        case "#40ABE1":
            print("Top")
            colorLabel.text = "Top"
            break
        case "#F06362":
            print("Left")
            colorLabel.text = "Left"
            break
        case "#00B3AD":
            print("Right")
            colorLabel.text = "Right"
            break
        case "#2862AD":
            print("Middle")
            colorLabel.text = "Middle"
            break
        case "#F68921":
            print("Bottom Most")
            colorLabel.text = "Bottom Most"
            break
        case "#DC407C":
            print("Back")
            colorLabel.text = "Back"
            break
        case "#7460A8":
            print("Bottom")
            colorLabel.text = "Bottom"
            break
        default:
            print("default")
            colorLabel.text = "default"
            return
        }
        
        var destinationColor  = UIColor.init(rgbColorCodeRed: 224, green: 93, blue: 80, alpha: 1.0)
        var isSelectedPart = false
        
        if selectedColors.keys.contains(resultColor.hexStringFromColor())
        {
            selectedColors[resultColor.hexStringFromColor()] = !(selectedColors[resultColor.hexStringFromColor()] ?? false)
            
            if selectedColors[resultColor.hexStringFromColor()]!
            {
                destinationColor  = UIColor.init(rgbColorCodeRed: 245, green: 217, blue: 207, alpha: 1.0)
                isSelectedPart = false
            }
        }
        else
        {
            selectedColors[resultColor.hexStringFromColor()] = false
            isSelectedPart = true
        }
        
        self.fakeImageView.image = self.replaceColor(sourceColor: UIColor(red: resultColor.rgba.red, green: resultColor.rgba.green, blue: resultColor.rgba.blue, alpha: resultColor.rgba.alpha)
        , destColor: destinationColor, image: self.fakeImageView.image!, tolerance: 0, isSelected: isSelectedPart)
    }
    
    //MARK:- Helper
    
    func getPixelColorAtPoint(point: CGPoint, sourceView: UIView) -> UIColor
    {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context!.translateBy(x: -point.x, y: -point.y)
        
        sourceView.layer.render(in: context!)
        let color: UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                     green: CGFloat(pixel[1])/255.0,
                                     blue: CGFloat(pixel[2])/255.0,
                                     alpha: CGFloat(pixel[3])/255.0)
        return color
    }
    
    func processPixels(in fakeImage: UIImage) -> UIImage?
    {
        guard let inputCGImage = fakeImage.cgImage else
        {
            print("unable to get cgImage")
            return nil
        }
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let fakeImageWidth   = inputCGImage.width
        let fakeImageHeight  = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * fakeImageWidth
        let bitmapInfo       = RGBA32.bitmapInfo

        guard let context = CGContext(data: nil,
                                      width: fakeImageWidth,
                                      height: fakeImageHeight,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo)
        else
        {
            print("unable to create context")
            return nil
        }
        
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: fakeImageWidth, height: fakeImageHeight))

        guard let buffer = context.data else
        {
            print("unable to get context data")
            return nil
        }

        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: fakeImageWidth * fakeImageHeight)
        
        for row in 0 ..< Int(fakeImageHeight)
        {
            for column in 0 ..< Int(fakeImageWidth)
            {
                let offset = row * fakeImageWidth + column
                print(pixelBuffer[offset])
                if pixelBuffer[offset] == .white
                {
                    pixelBuffer[offset] = .red
                }
            }
        }

        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: fakeImage.scale, orientation: fakeImage.imageOrientation)

        return outputImage
    }
    
    /**
    * parameter color: source color, which is must be replaced
    * parameter withColor: target color
    * parameter image: value in range from 0 to 1
    */
    
    func replaceColor(sourceColor: UIColor, destColor: UIColor, image: UIImage, tolerance: CGFloat, isSelected:Bool? = true) -> UIImage
    {
        // This function expects to get source color(color which is supposed to be replaced)
        // and target color in RGBA color space, hence we expect to get 4 color components: r, g, b, a
        
        assert(sourceColor.cgColor.numberOfComponents == 4 && destColor.cgColor.numberOfComponents == 4,
               "Must be RGBA colorspace")
        
        // Allocate bitmap in memory with the same width and size as destination image
        
        let imageRef2 = self.realImageView.image!.cgImage!
        let width2 = imageRef2.width
        let height2 = imageRef2.height

        let bytesPerPixel2 = 4
        let bytesPerRow2 = bytesPerPixel2 * width2;
        let bitsPerComponent2 = 8
        let bitmapByteCountSourrce = bytesPerRow2 * height2

        let rawDataSource = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCountSourrce)

        let context2 = CGContext(data: rawDataSource, width: width2, height: height2, bitsPerComponent: bitsPerComponent2, bytesPerRow: bytesPerRow2, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        let rc2 = CGRect(x: 0, y: 0, width: width2, height: height2)

        // Draw source image on created context
        
        context2!.draw(imageRef2, in: rc2)

        // Allocate bitmap in memory with the same width and size as source image
        
        let imageRef = image.cgImage!
        let width = imageRef.width
        let height = imageRef.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width;
        let bitsPerComponent = 8
        let bitmapByteCount = bytesPerRow * height

        let rawDataDest = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)

        let context = CGContext(data: rawDataDest, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        let rc = CGRect(x: 0, y: 0, width: width, height: height)

        // Draw source image on created context
        
        context!.draw(imageRef, in: rc)

        // Get color components from replacement color
        
        let withColorComponents = destColor.cgColor.components
        let r2 = UInt8(withColorComponents![0] * 255)
        let g2 = UInt8(withColorComponents![1] * 255)
        let b2 = UInt8(withColorComponents![2] * 255)
        let a2 = UInt8(withColorComponents![3] * 255)

        // Prepare to iterate over image pixels
        
        var byteIndex = 0

        while byteIndex < bitmapByteCountSourrce
        {
            // Get color of current pixel
            
            let red = CGFloat(rawDataSource[byteIndex + 0]) / 255
            let green = CGFloat(rawDataSource[byteIndex + 1]) / 255
            let blue = CGFloat(rawDataSource[byteIndex + 2]) / 255
            let alpha = CGFloat(rawDataSource[byteIndex + 3]) / 255

            let currentColorSource = UIColor(red: red, green: green, blue: blue, alpha: alpha);

            // Compare two colors using given tolerance value
            
            if compareColor(color: sourceColor, withColor: currentColorSource , withTolerance: tolerance)
            {
                // If the're 'similar', then replace pixel color with given target color
                
                rawDataDest[byteIndex + 0] = r2
                rawDataDest[byteIndex + 1] = g2
                rawDataDest[byteIndex + 2] = b2
                rawDataDest[byteIndex + 3] = a2
            }
            else
            {
                
            }
            
            byteIndex = byteIndex + 4;
        }

        // Retrieve image from memory context
        
        let imgref = context!.makeImage()
        let result = UIImage(cgImage: imgref!)

        // Clean up a bit
        
        rawDataSource.deallocate()
        rawDataDest.deallocate()
        
//        free(rawDataSource)
//        free(rawDataDest)
        
        return result
    }

    func compareColor(color: UIColor, withColor: UIColor, withTolerance: CGFloat) -> Bool
    {
        var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0;
        var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0;

        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1);
        withColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2);

        return abs(r1 - r2) <= withTolerance &&
            abs(g1 - g2) <= withTolerance &&
            abs(b1 - b2) <= withTolerance &&
            abs(a1 - a2) <= withTolerance;
    }
    
}


extension ViewController : UIScrollViewDelegate
{
    //MARK:- UIScrollView

    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return zoomView
    }
}

extension UIColor
{
    //MARK:- UIColor
    
    convenience init(rgbColorCodeRed red: Int, green: Int, blue: Int, alpha: CGFloat)
    {

      let redPart: CGFloat = CGFloat(red) / 255
      let greenPart: CGFloat = CGFloat(green) / 255
      let bluePart: CGFloat = CGFloat(blue) / 255

      self.init(red: redPart, green: greenPart, blue: bluePart, alpha: alpha)

    }

    func hexStringFromColor() -> String
    {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        print(hexString)
        return hexString
    }
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
    
    var redComponent: CGFloat
    {
        var red: CGFloat = 0.0
        getRed(&red, green: nil, blue: nil, alpha: nil)
        
        return red
    }
    
    var greenComponent: CGFloat
    {
        var green: CGFloat = 0.0
        getRed(nil, green: &green, blue: nil, alpha: nil)
        
        return green
    }
    
    var blueComponent: CGFloat
    {
        var blue: CGFloat = 0.0
        getRed(nil, green: nil, blue: &blue, alpha: nil)
        
        return blue
    }
    
    var alphaComponent: CGFloat
    {
        var alpha: CGFloat = 0.0
        getRed(nil, green: nil, blue: nil, alpha: &alpha)
        
        return alpha
    }
}

