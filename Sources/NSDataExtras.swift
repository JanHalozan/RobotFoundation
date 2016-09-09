//
//  NSDataExtras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension Data {
	public mutating func appendUInt8(_ value: UInt8) {
		var mutableValue = value
		append(&mutableValue, count: MemoryLayout<UInt8>.size)
	}

	mutating func appendInt8(_ value: Int8) {
		var mutableValue = value
		withUnsafePointer(to: &mutableValue) { ptr in
			append(unsafeBitCast(ptr, to: UnsafePointer<UInt8>.self), count: MemoryLayout<Int8>.size)
		}
	}

	mutating func appendUInt16(_ value: UInt16) {
		var mutableValue = NSSwapHostShortToLittle(value)
		withUnsafePointer(to: &mutableValue) { ptr in
			append(unsafeBitCast(ptr, to: UnsafePointer<UInt8>.self), count: MemoryLayout<UInt16>.size)
		}
	}

	mutating func appendUInt32(_ value: UInt32) {
		var mutableValue = NSSwapHostIntToLittle(value)
		withUnsafePointer(to: &mutableValue) { ptr in
			append(unsafeBitCast(ptr, to: UnsafePointer<UInt8>.self), count: MemoryLayout<UInt32>.size)
		}
	}

	mutating func appendString(_ string: String) {
		for unit in string.utf8 {
			appendUInt8(unit)
		}

		// null-terminated
		appendUInt8(0)
	}
}

extension Data {
	func dataByAppendingData(_ data: Data) -> Data {
		var mutableData = self
		mutableData.append(data)
		return mutableData
	}

	public func readFloatAtIndex(_ index: Int) -> Float {
		var value = Float32()
		withUnsafeMutablePointer(to: &value) { ptr in
			copyBytes(to: unsafeBitCast(ptr, to: UnsafeMutablePointer<UInt8>.self), from: index..<(index+4))
		}

		return value
	}

	public func readInt8AtIndex(_ index: Int) -> Int8 {
		var value = Int8()
		withUnsafeMutablePointer(to: &value) { ptr in
			copyBytes(to: unsafeBitCast(ptr, to: UnsafeMutablePointer<UInt8>.self), from: index..<(index+1))
		}

		return value
	}

	public func readUInt8AtIndex(_ index: Int) -> UInt8 {
		var value = UInt8()
		copyBytes(to: &value, from: index..<(index+1))

		return value
	}

	func readUInt16AtIndex(_ index: Int) -> UInt16 {
		var value = UInt16()
		withUnsafeMutablePointer(to: &value) { ptr in
			copyBytes(to: unsafeBitCast(ptr, to: UnsafeMutablePointer<UInt8>.self), from: index..<(index+2))
		}

		return NSSwapLittleShortToHost(value)
	}

	func readUInt32AtIndex(_ index: Int) -> UInt32 {
		var value = UInt32()
		withUnsafeMutablePointer(to: &value) { ptr in
			copyBytes(to: unsafeBitCast(ptr, to: UnsafeMutablePointer<UInt8>.self), from: index..<(index+4))
		}

		return NSSwapLittleIntToHost(value)
	}

	func readStringAtIndex(_ index: Int, length: Int) -> String {
		var stringBuffer = [UInt8](repeating: 0 /* null terminated */, count: length + 1)
		copyBytes(to: &stringBuffer, from: index..<(index+length))

		return stringBuffer.withUnsafeBufferPointer { ptr in
			return String(validatingUTF8: unsafeBitCast(ptr.baseAddress!, to: UnsafePointer<Int8>.self))
		} ?? ""
	}

	func readStringOfUnknownLengthAtIndex(_ index: Int, maxLength: Int) -> String {
		var stringBuffer = [UInt8](repeating: 0, count: maxLength)
		copyBytes(to: &stringBuffer, from: index..<(index+maxLength))

		return stringBuffer.withUnsafeBufferPointer { ptr in
			return String(validatingUTF8: unsafeBitCast(ptr.baseAddress!, to: UnsafePointer<Int8>.self))
		} ?? ""
	}
}
