//
//  EV3ReadLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3ReadLightType: UInt8 {
	case Reflected = 0
	case Ambient = 3
}

struct EV3ReadLightCommand: EV3Command {
	let port: EV3Port
	let lightType: EV3ReadLightType

	var responseType: MindstormsResponse.Type {
		return EV3PercentFloatResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var numberOfGlobals: UInt8 {
		return 4 // 32-bit float
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		mutableData.appendUInt8(EV3OpCode.InputDevice.rawValue)
		mutableData.appendUInt8(EV3OpSubcode.ReadySI.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(lightType.rawValue)
		mutableData.appendUInt8(EV3Dataset.One.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
