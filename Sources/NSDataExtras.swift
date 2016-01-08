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

	func appendUInt32(var value: UInt32) {
		value = NSSwapHostIntToLittle(value)
		appendBytes(&value, length: sizeof(UInt32))
	}

	func appendString(string: String) {
		for unit in string.utf8 {
			appendUInt8(unit)
		}

		// null-terminated
		appendUInt8(0)
	}
}

extension NSData {
	func dataByAppendingData(data: NSData) -> NSData {
		guard let mutableData = mutableCopy() as? NSMutableData else {
			assertionFailure()
			return data
		}

		mutableData.appendData(data)

		guard let singleData = mutableData.copy() as? NSData else {
			assertionFailure()
			return mutableData
		}

		return singleData
	}

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

	func readUInt32AtIndex(index: Int) -> UInt32 {
		var value = UInt32()
		getBytes(&value, range: NSMakeRange(index, 4))

		return NSSwapLittleIntToHost(value)
	}

	func readStringAtIndex(index: Int, length: Int) -> String {
		var stringBuffer = [Int8](count: length + 1 /* null terminated */, repeatedValue: 0)
		getBytes(&stringBuffer, range: NSMakeRange(index, length))

		return NSString(UTF8String: stringBuffer) as? String ?? ""
	}
}
