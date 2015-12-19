//
//  NSDataNXTExtras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension NSString {
	var dataForFilename: NSData {
		let clippedName = self.length > 19 ? substringToIndex(20) : self
		return NSData(bytes: clippedName.UTF8String, length: 20)
	}
}

extension NSMutableData {
	func appendNXTFilename(filename: NSString) {
		appendData(filename.dataForFilename)
	}
}
