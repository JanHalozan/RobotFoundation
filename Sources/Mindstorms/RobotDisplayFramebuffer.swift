//
//  RobotDisplayFramebuffer.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

#if os(OSX)

import AppKit

extension NSBitmapImageRep {
	func set1BitValue(value: Bool, atY y: Int, x: Int) {
		if value {
			var pixel = [0, 0, 0, 255]
			setPixel(&pixel, atX: x, y: y)
		} else {
			var pixel = [255, 255, 255, 255]
			setPixel(&pixel, atX: x, y: y)
		}
	}
}

#endif
