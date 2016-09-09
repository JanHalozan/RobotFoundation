//
//  NXTFindNextCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct NXTFindNextCommand: NXTCommand {
	public let handle: UInt8

	public init(handle: UInt8) {
		self.handle = handle
	}

	public var responseType: MindstormsResponse.Type {
		return NXTFileResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x87
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(handle)
		return data
	}
}
