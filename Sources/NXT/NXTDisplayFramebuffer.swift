//
//  NXTDisplayFramebuffer.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

public func BitmapImageRepForNXTDisplayFramebuffer(data: NSData) -> NSBitmapImageRep {
	guard let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: kNXTScreenWidth, pixelsHigh: kNXTScreenHeight, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bitmapFormat: [], bytesPerRow: 0, bitsPerPixel: 32) else {
		fatalError()
	}

	let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)

	for y in 0..<kNXTScreenHeight {
		for x in 0..<kNXTScreenWidth {
			if bytes[y/8 * kNXTScreenWidth + x] & UInt8(1 << (y % 8)) > 0 {
				imageRep.set1BitValue(true, atY: y, x: x)
			} else {
				imageRep.set1BitValue(false, atY: y, x: x)
			}
		}
	}

	return imageRep
}
