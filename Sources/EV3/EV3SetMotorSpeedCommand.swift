//
//  EV3SetMotorSpeedCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

struct EV3SetMotorSpeedCommand: EV3DirectCommand {
	let port: EV3OutputPortOptions
	let speed: UInt8

	var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputSpeed.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendUInt8(speed)

		return mutableData.copy() as! NSData
	}
}
