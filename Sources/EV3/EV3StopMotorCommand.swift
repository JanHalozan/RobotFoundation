//
//  EV3StopMotorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public enum EV3StopType: UInt8 {
	case Coast = 0
	case Brake = 1
}

public struct EV3StopMotorCommand: EV3DirectCommand {
	public let port: EV3OutputPortOptions
	public let stopType: EV3StopType

	public init(port: EV3OutputPortOptions, stopType: EV3StopType) {
		self.port = port
		self.stopType = stopType
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputStop.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendUInt8(stopType.rawValue)

		return mutableData.copy() as! NSData
	}
}
