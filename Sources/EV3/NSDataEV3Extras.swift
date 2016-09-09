//
//  NSDataEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension Data {
	mutating func appendLC1(_ value: UInt8) {
		appendUInt8(0x81)
		appendUInt8(value)
	}

	mutating func appendLC2(_ value: UInt16) {
		appendUInt8(0x82)
		appendUInt16(value)
	}

	mutating func appendLC4(_ value: UInt32) {
		appendUInt8(0x83)
		appendUInt32(value)
	}

	mutating func appendGV2(_ index: UInt16) {
		appendUInt8(0x80  | 0x40 | 0x20 | 2)
		appendUInt16(index)
	}

	mutating func appendLCS(_ string: String) {
		appendUInt8(0x84)
		appendString(string)
	}
}
