//
//  NSDataEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension NSMutableData {
	func appendLC1(value: UInt8) {
		var lc1 = UInt8(0x81)

		appendBytes(&lc1, length: sizeof(UInt8))
		appendUInt8(value)
	}

	func appendLC2(value: UInt16) {
		var lc2 = UInt8(0x82)

		appendBytes(&lc2, length: sizeof(UInt8))
		appendUInt16(value)
	}

	func appendUInt8(var value: UInt8) {
		appendBytes(&value, length: sizeof(UInt8))
	}

	func appendUInt16(var value: UInt16) {
		value = NSSwapHostShortToLittle(value)
		appendBytes(&value, length: sizeof(UInt16))
	}
}
