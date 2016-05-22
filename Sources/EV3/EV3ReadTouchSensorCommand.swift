//
//  EV3ReadTouchSensorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

// 1 if on, 0 if off.
private let kEV3TouchSensorBooleanMode = UInt8(0)

public struct EV3ReadTouchSensorCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public var responseType: MindstormsResponse.Type {
		return EV3BooleanResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputReadSI.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(kEV3TouchSensorBooleanMode)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
