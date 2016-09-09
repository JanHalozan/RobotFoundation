//
//  NXTGetInputValuesCommand.swift
//  RobotFoundation
//
//  Created by Matt on 8/17/16.
//

import Foundation

public struct NXTGetInputValuesCommand: NXTCommand {
	let port: NXTInputPort

	public init(port: NXTInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return NXTInputValuesResponse.self
	}

	public var type: MindstormsCommandType {
		return .direct
	}

	public var identifier: UInt8 {
		return 0x07
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(port.rawValue)
		return data
	}
}
