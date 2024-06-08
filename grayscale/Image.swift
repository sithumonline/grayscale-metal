//
//  Image.swift
//  grayscale
//
//  Created by sithum sandeepa on 2024-06-07.
//

import AppKit
import Accelerate

func getImageMatrix(from url: URL) -> Matrix<UInt8>? {
    guard let nsImage = NSImage(contentsOf: url),
          let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to load image or convert to CGImage")
        return nil
    }
    
    do {
        // Initialize the vImage_Buffer using the non-optional cgImage
        let sourceBuffer = try vImage_Buffer(cgImage: cgImage)
        
        // Ensure sourceBuffer.data is non-nil and unwrap it safely
        guard let data = sourceBuffer.data else {
            print("Failed to get data from sourceBuffer")
            return nil
        }
        
        let dataPointer = data.bindMemory(to: UInt8.self, capacity: sourceBuffer.rowBytes * Int(sourceBuffer.height))
        
        // Ensure width and height are non-optional
        let width = Int(sourceBuffer.width)
        let height = Int(sourceBuffer.height)
        
        let stride = 4 // Assuming RGBA format, so 4 bytes per pixel
        let input = Matrix<UInt8>(w: width * stride, h: height, d: 1)
        
        for y in 0..<height {
            for x in 0..<width {
                input.set(x: (x * stride) + 0, y: y, z: 0, v: dataPointer[(y * sourceBuffer.rowBytes) + (x * stride) + 0]) // Red
                input.set(x: (x * stride) + 1, y: y, z: 0, v: dataPointer[(y * sourceBuffer.rowBytes) + (x * stride) + 1]) // Green
                input.set(x: (x * stride) + 2, y: y, z: 0, v: dataPointer[(y * sourceBuffer.rowBytes) + (x * stride) + 2]) // Blue
                input.set(x: (x * stride) + 3, y: y, z: 0, v: dataPointer[(y * sourceBuffer.rowBytes) + (x * stride) + 3]) // Alpha
            }
        }
        
        return input
    } catch {
        print("Error initializing vImage_Buffer: \(error)")
        return nil
    }
}


func saveMatrixAsImage(matrix: Matrix<UInt8>, to url: URL) {
    let width = matrix.w
    let height = matrix.h
    
    // Each pixel is 4 bytes (RGBA), so the number of bytes per row is width * 4
    let bytesPerRow = width * 4
    
    // Allocate memory for the output buffer
    let bufferSize = height * bytesPerRow
    let bufferPointer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1)
    
    var outputBuffer = vImage_Buffer(data: bufferPointer, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
    
    // Fill the buffer with the matrix data
    for y in 0..<height {
        for x in 0..<width {
            let value = matrix.get(x: x, y: y, z: 0)
            let offset = (y * bytesPerRow) + (x * 4)
            bufferPointer.storeBytes(of: value, toByteOffset: offset, as: UInt8.self)     // R
            bufferPointer.storeBytes(of: value, toByteOffset: offset + 1, as: UInt8.self) // G
            bufferPointer.storeBytes(of: value, toByteOffset: offset + 2, as: UInt8.self) // B
            bufferPointer.storeBytes(of: 255, toByteOffset: offset + 3, as: UInt8.self)   // A
        }
    }
    
    var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceRGB()),
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                      version: 0, decode: nil, renderingIntent: .defaultIntent)
    
    // Create a CGImage from the buffer
    let destinationCGImage = vImageCreateCGImageFromBuffer(&outputBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)
    
    if let destinationCGImage = destinationCGImage {
        let destinationImage = NSImage(cgImage: destinationCGImage.takeRetainedValue(), size: NSSize(width: width, height: height))
    }
    
    if let destinationCGImage = destinationCGImage {
        let destinationImage = NSImage(cgImage: destinationCGImage.takeRetainedValue(), size: NSSize(width: width, height: height))
        if let tiffData = destinationImage.tiffRepresentation {
            do {
                try tiffData.write(to: url)
                print("Image saved successfully at \(url.path).")
            } catch {
                print("Failed to write image to disk: \(error)")
            }
        }
    }
    
    // Deallocate the buffer memory
    bufferPointer.deallocate()
}
