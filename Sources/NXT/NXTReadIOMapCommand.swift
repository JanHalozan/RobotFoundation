//
//  NXTReadIOMapCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

public struct NXTReadIOMapCommand: NXTCommand {
	public let module: UInt32
	public let offset: UInt16
	public let bytesToRead: UInt16 // max seems to be 64 bytes

	public init(module: UInt32, offset: UInt16, bytesToRead: UInt16) {
		self.module = module
		self.offset = offset
		self.bytesToRead = bytesToRead
	}

	public var responseType: MindstormsResponse.Type {
		return NXTIOMapResponse.self
	}

	public var type: MindstormsCommandType {
		return .System
	}

	public var identifier: UInt8 {
		return 0x94
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt32(module)
		mutableData.appendUInt16(offset)
		mutableData.appendUInt16(bytesToRead)
		return mutableData.copy() as! NSData
	}
}

