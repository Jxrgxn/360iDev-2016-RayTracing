//
//  ViewController.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 12/23/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Cocoa



struct RawImage {
    var data: NSMutableData
    let width: UInt
    let height: UInt

    var numBytes: Int {
        return Int(width) * Int(height) * 4
    }
    
    init (_ width: UInt, _ height: UInt) {
        self.width = width
        self.height = height
        
        // Reserve space for the data
        let numBytes = Int(width) * Int(height) * 4
        let imageData = UnsafeMutablePointer<UInt8>.alloc(numBytes)
        
        // Initialize data to opaque black
        for i in 0 ..< Int(width*height) {
            imageData[i*4] = 0
            imageData[i*4 + 1] = 0
            imageData[i*4 + 2] = 0
            imageData[i*4 + 3] = 255
        }

        self.data = NSMutableData(bytes: imageData, length: numBytes)
        
        free(imageData)
    }
    
    func setPixel (idx: Int, _ color: RGBColor) {
        let p = UnsafeMutablePointer<UInt8>(self.data.mutableBytes)
        
        let idx4 = 4 * idx
        p[idx4] = color.r
        p[idx4 + 1] = color.g
        p[idx4 + 2] = color.b
        p[idx4 + 3] = 255
    }
    
    func setPixel (i: Int, _ j: Int, color: RGBColor) {
        let idx: Int = (j * Int(width) + i)
        setPixel(idx, color)
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    
    var img: RawImage = RawImage(0, 0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let a⃗ = Vector(1, 2, 3)
        let b⃗ = Vector(4, 5, 6)
        let d = a⃗ ⋅ b⃗
        
        print("Dot product: \(d)")
        
        img = self.rayTrace()
        displayRenderData(img.data, width: img.width, height: img.height)
    }
    

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    func displayRenderData (imgBytes: NSData, width: UInt, height: UInt) {
        let bufferLength = width * height * 4
        let blah: UnsafePointer<Void> = nil
        
//        let provider: CGDataProvider = CGDataProviderCreateWithData(nil, imgBytes.bytes, bufferLength, nil)
        let provider = CGDataProviderCreateWithCFData(imgBytes)
        
        let bytesPerRow = 4 * width
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        
        let blah2: UnsafePointer<CGFloat> = nil
        let imgRef: CGImage = CGImageCreate(Int(width), Int(height),
            8, // Bits per component
            32, // Bits per pixel
            Int(bytesPerRow),
            colorSpaceRef,
            bitmapInfo,
            provider!, // data provider
            blah2, // decode
            true, // should interpolate
            renderingIntent)!

        let imgSize = CGSizeMake(CGFloat(width), CGFloat(height))
        let img = NSImage(CGImage: imgRef, size: imgSize)
        
        // Save image to file to check
        saveImgToFile(imgRef)
        
        imageView.image = img
    }
    

    func rayTrace () -> RawImage {
        let imgSize: UInt = 251
        let w = imgSize as UInt
        let h = imgSize as UInt
        
        let img = RawImage(w, h)
        
        let cam: Camera = Camera()
        
        let rays = raysForCamera(cam, samplesPerSide: Int(imgSize))
        
        let scene = Scene()

        scene.objects = [
            Sphere(Point( 0.0, 0.0, -3.0), 0.5),
            Sphere(Point(-1.0, 0.0, -3.0), 0.5, color: blue),
            Sphere(Point( 1.0, 0.0, -3.0), 0.5, color: green),
            Sphere(Point( 0.0, 4000.5, -3.0), 4000.0, color: grayColorFromFloat(0.3))
        ]
        
        let intersections = rays.map({ scene.castRay($0) })
        
        let indices = 0 ..< intersections.count
        
        for (intersection, idx) in Zip2Sequence(intersections, indices) {
            if let intersection = intersection {
                let c = intersection.light(scene)
                img.setPixel(idx, c)
                
                /* Z buffer distance
                let p = intersection.rayPoint.point
                let d = intersection.rayPoint.distance
                
                // Scale distance to clip plane
                let normalizedDist = d / cam.farClip
                let pixelColor = grayColorFromFloat(1.0 - normalizedDist)
                img.setPixel(idx, pixelColor)
                */
            }
        }
        
        return img
    }
    
    func saveImgToFile (img: CGImage) -> Bool {
        let url = NSURL.fileURLWithPath("/Users/jblocksom/Desktop/raytrace.png")
        guard let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil) else {
            return false
        }
        
        CGImageDestinationAddImage(destination, img, nil)
        CGImageDestinationFinalize(destination)
        return true
    }
    
}

