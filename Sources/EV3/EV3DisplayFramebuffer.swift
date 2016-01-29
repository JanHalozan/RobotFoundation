//
//  EV3DisplayFramebuffer.swift
//  RobotFoundation
//
//  Created by Matt on 12/25/15.
//

#if os(OSX)

import AppKit

private let displayHeight = 128
private let displayWidth = 178

public func BitmapImageRepForEV3DisplayFramebuffer(data: NSData) -> NSBitmapImageRep {
	guard let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: displayWidth, pixelsHigh: displayHeight, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bitmapFormat: [], bytesPerRow: 0, bitsPerPixel: 32) else {
		fatalError()
	}

	for offset in 0..<data.length {
		let row = offset / 60
		let column = offset % 60
		let pixel = data.readUInt8AtIndex(offset)

		if column < 59 {
			// 3 pixels per byte
			// bit 7 (or 6) is pixel 0
			imageRep.set1BitValue((pixel & 128) > 0, atY: row, x: column * 3)

			// bit 4 (or 3) is pixel 1
			imageRep.set1BitValue((pixel & 16) > 0, atY: row, x: column * 3 + 1)

			// bit 1 (or 0) is pixel 2
			imageRep.set1BitValue((pixel & 2) > 0, atY: row, x: column * 3 + 2)
		} else if column == 59 {
			// the last pixel
			imageRep.set1BitValue((pixel & 128) > 0, atY: row, x: displayWidth - 1)
		} else {
			assertionFailure()
		}
	}

	return imageRep
}

#endif
