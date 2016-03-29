//
//  NXTPlayToneCommand.swift
//  RobotFoundation
//
//  Created by Matt on 3/29/16.
//

import Foundation

public struct NXTPlayToneCommand: NXTCommand {
	public let frequency: UInt16
	public let duration: UInt16

	public init(frequency: UInt16, duration: UInt16) {
		self.frequency = frequency
		self.duration = duration
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x03
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt16(frequency)
		data.appendUInt16(duration)
		return data.copy() as! NSData
	}
}
