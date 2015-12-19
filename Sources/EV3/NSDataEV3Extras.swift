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
}
