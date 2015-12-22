//
//  EV3SetSensorModeCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

struct EV3SetSensorModeCommand: EV3Command {
	let port: EV3Port
	let mode: UInt8

	var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var numberOfGlobals: UInt8 {
		return 1
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		mutableData.appendUInt8(EV3OpCode.InputReadSI.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(0)
		mutableData.appendUInt8(mode)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
