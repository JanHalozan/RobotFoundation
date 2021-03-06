//
//  NXTCloseCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct NXTCloseCommand: NXTCommand {
	public let handle: UInt8

	public init(handle: UInt8) {
		self.handle = handle
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x84
	}

	public var payloadData: Data {
		var mutableData = Data()
		mutableData.appendUInt8(handle)

		return mutableData
	}
}
