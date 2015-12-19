//
//  NSDataExtras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension NSMutableData {
	func appendUInt8(var value: UInt8) {
		appendBytes(&value, length: sizeof(UInt8))
	}

	func appendUInt16(var value: UInt16) {
		value = NSSwapHostShortToLittle(value)
		appendBytes(&value, length: sizeof(UInt16))
	}
}

extension NSData {
	func readUInt8AtIndex(index: Int) -> UInt8 {
		var value = UInt8()
		getBytes(&value, range: NSMakeRange(index, 1))

		return value
	}

	func readUInt16AtIndex(index: Int) -> UInt16 {
		var value = UInt16()
		getBytes(&value, range: NSMakeRange(index, 2))

		return NSSwapLittleShortToHost(value)
	}
}
