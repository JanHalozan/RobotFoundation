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

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiButton.rawValue)
		mutableData.appendUInt8(EV3ButtonOpSubcode.pressed.rawValue)
		mutableData.appendUInt8(button.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
