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
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x07
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		return data.copy() as! NSData
	}
}
