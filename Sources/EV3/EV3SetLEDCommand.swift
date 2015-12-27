//
//  EV3SetLEDCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3LEDPattern: UInt8 {
	case None = 0, Green, Red, Orange
	case FlashingGreen, FlashingRed, FlashingOrange
	case PulsingGreen, PulsingRed, PulsingOrange
}

public struct EV3SetLEDCommand: EV3DirectCommand {
	public let pattern: EV3LEDPattern

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIWrite.rawValue)
		mutableData.appendUInt8(EV3UIWriteOpSubcode.LED.rawValue)

		mutableData.appendUInt8(pattern.rawValue)
		mutableData.appendUInt8(0x1)

		return mutableData.copy() as! NSData
	}
}
