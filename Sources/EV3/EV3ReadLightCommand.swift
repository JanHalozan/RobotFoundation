//
//  EV3ReadLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3ReadLightType: UInt8 {
	// Returns a percentage (0-100)
	case Reflected = 0
	case Ambient = 1
}

struct EV3ReadLightCommand: EV3DirectCommand {
	let port: EV3InputPort
	let lightType: EV3ReadLightType

	var responseType: MindstormsResponse.Type {
		return EV3PercentByteResponse.self
	}

	var globalSpaceSize: UInt16 {
		return 1
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		mutableData.appendUInt8(EV3OpCode.InputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(lightType.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
