//
//  EV3ReadOutputCommand.swift
//  RobotFoundation
//
//  Created by Matt on 4/28/16.
//

import Foundation

public struct EV3ReadOutputCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions

	public init(ports: EV3OutputPortOptions) {
		self.ports = ports
	}

	public var responseType: MindstormsResponse.Type {
		return EV3OutputSpeedTachoResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 5
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)

		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar4.rawValue)

		return mutableData.copy() as! NSData
	}
}

