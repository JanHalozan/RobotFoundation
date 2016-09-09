//
//  EV3SetLEDCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3LEDPattern: UInt8 {
	case none = 0, green, red, orange
	case flashingGreen, flashingRed, flashingOrange
	case pulsingGreen, pulsingRed, pulsingOrange
}

public struct EV3SetLEDCommand: EV3DirectCommand {
	public let pattern: EV3LEDPattern

	public init(pattern: EV3LEDPattern) {
		self.pattern = pattern
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiWrite.rawValue)
		mutableData.appendUInt8(EV3UIWriteOpSubcode.led.rawValue)

		mutableData.appendUInt8(pattern.rawValue)

		return mutableData
	}
}
