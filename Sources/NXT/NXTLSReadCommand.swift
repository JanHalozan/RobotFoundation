//
//  NXTLSReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 9/7/16.
//

import Foundation

public struct NXTLSReadCommand: NXTCommand {
	public let port: NXTInputPort

	public init(port: NXTInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return NXTLSReadResponse.self
	}

	public var type: MindstormsCommandType {
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x10
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		return data.copy() as! NSData
	}
}
