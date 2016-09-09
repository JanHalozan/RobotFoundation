//
//  NXTSetBrickNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/28/16.
//

import Foundation

public struct NXTSetBrickNameCommand: NXTCommand {
	public let name: String

	public init(name: String) {
		self.name = name
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x98
	}

	public var payloadData: Data {
		var data = Data()
		data.appendNXTBrickName(name)
		return data
	}
}

