//
//  EV3StopMotorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

enum EV3StopType: UInt8 {
	case Coast = 0
	case Brake = 1
}

struct EV3StopMotorCommand: EV3DirectCommand {
	let port: EV3OutputPortOptions
	let stopType: EV3StopType

	var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	var numberOfGlobals: UInt8 {
		return 0
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputStop.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendUInt8(stopType.rawValue)

		return mutableData.copy() as! NSData
	}
}
