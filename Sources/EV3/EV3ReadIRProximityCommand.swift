//
//  EV3ReadIRProximityCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/22/16.
//

import Foundation

private let kEV3IRSensorProximityMode = UInt8(0)

public struct EV3ReadIRProximityCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3PercentByteResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(kEV3IRSensorProximityMode)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}

