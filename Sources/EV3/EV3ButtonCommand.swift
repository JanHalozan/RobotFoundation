//
//  EV3ButtonCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/9/16.
//

import Foundation

public enum EV3ButtonType: UInt8 {
	case Press = 5
	case Release = 6
}

public struct EV3ButtonCommand: EV3DirectCommand {
	public let button: EV3Button
	public let type: EV3ButtonType

	public init(button: EV3Button, type: EV3ButtonType) {
		self.button = button
		self.type = type
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIButton.rawValue)
		mutableData.appendUInt8(type.rawValue)
		mutableData.appendUInt8(button.rawValue)

		return mutableData.copy() as! NSData
	}
}
