//
//  NXTWriteIOMapCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTWriteIOMapCommand: NXTCommand {
	public let moduleID: UInt32
	public let offset: UInt16
	public let contents: Data

	public init(moduleID: UInt32, offset: UInt16, contents: Data) {
		self.moduleID = moduleID
		self.offset = offset
		self.contents = contents
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x95
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt32(moduleID)
		data.appendUInt16(offset)
		data.appendUInt16(UInt16(contents.count))
		data.append(contents)
		return data
	}
}
