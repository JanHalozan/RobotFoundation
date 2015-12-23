//
//  EV3StartMotorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

struct EV3StartMotorCommand: EV3Command {
	let port: EV3OutputPortOptions

	var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var numberOfGlobals: UInt8 {
		return 0
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputStart.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		return mutableData.copy() as! NSData
	}
}
