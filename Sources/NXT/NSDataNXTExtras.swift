//
//  NSDataNXTExtras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension NSString {
	var dataForFilename: NSData {
		let clippedName = length > 19 ? substringToIndex(19) : self
		let paddedName = clippedName.stringByAppendingString("\0")

		return paddedName.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
	}
}

extension NSMutableData {
	func appendNXTFilename(filename: NSString) {
		appendData(filename.dataForFilename)
	}

	func appendNXTBrickName(name: NSString) {
		let clippedName = name.length > 15 ? name.substringToIndex(15) : name
		let paddedName = clippedName.stringByAppendingString("\0")

		guard let data = paddedName.dataUsingEncoding(NSUTF8StringEncoding) else {
			assertionFailure()
			return
		}

		appendData(data)
	}
}
