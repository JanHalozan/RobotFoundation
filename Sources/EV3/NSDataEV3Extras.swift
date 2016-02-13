//
//  NSDataEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension NSMutableData {
	func appendLC1(value: UInt8) {
		appendUInt8(0x81)
		appendUInt8(value)
	}

	func appendLC2(value: UInt16) {
		appendUInt8(0x82)
		appendUInt16(value)
	}

	func appendLC4(value: UInt32) {
		appendUInt8(0x83)
		appendUInt32(value)
	}
}
