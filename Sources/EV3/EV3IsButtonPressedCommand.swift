//
//  EV3IsButtonPressedCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3IsButtonPressedCommand: EV3DirectCommand {
	public let button: EV3ButtonConst

	public init(button: EV3ButtonConst) {
		self.button = button
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ButtonPressedResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIButton.rawValue)
		mutableData.appendUInt8(EV3ButtonOpSubcode.Pressed.rawValue)
		mutableData.appendUInt8(button.rawValue)
		mutableData.appendUInt8(offset)

		return mutableData.copy() as! NSData
	}
}
