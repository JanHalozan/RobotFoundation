//
//  EV3ReadTouchSensor.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

struct EV3ReadTouchSensorCommand: EV3Command {
	let port: EV3Port

	var responseType: MindstormsResponse.Type {
		return EV3PercentByteResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var numberOfGlobals: UInt8 {
		return 1 // 32-bit float
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		mutableData.appendUInt8(EV3OpCode.InputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(0)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
