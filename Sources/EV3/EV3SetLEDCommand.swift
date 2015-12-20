//
//  EV3SetLEDCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3LEDPattern: UInt8 {
	case None = 0, Green, Red, Orange
	case FlashingGreen, FlashingRed, FlashingOrange
	case PulsingGreen, PulsingRed, PulsingOrange
}

struct EV3SetLEDCommand: EV3Command {
	let pattern: EV3LEDPattern

	var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		// UI write op code
		mutableData.appendUInt8(0x82)

		// LED command
		mutableData.appendUInt8(27)

		mutableData.appendUInt8(pattern.rawValue)
		mutableData.appendUInt8(0x1)

		return mutableData.copy() as! NSData
	}
}
