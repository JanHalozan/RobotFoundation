//
//  NXTReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTReadCommand: NXTCommand {
	public let handle: UInt8
	public let bytesToRead: UInt16 // max size: 64 bytes

	public init(handle: UInt8, bytesToRead: UInt16) {
		self.handle = handle
		self.bytesToRead = bytesToRead
	}

	public var responseType: MindstormsResponse.Type {
		return NXTDataResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x82
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(handle)
		data.appendUInt16(bytesToRead)
		return data
	}
}
