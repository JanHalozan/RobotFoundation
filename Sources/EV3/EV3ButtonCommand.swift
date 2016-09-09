//
//  EV3ButtonCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/9/16.
//

import Foundation

public enum EV3ButtonType: UInt8 {
	case press = 5
	case release = 6
}

public struct EV3ButtonCommand: EV3DirectCommand {
	public let button: EV3ButtonConst
	public let type: EV3ButtonType

	public init(button: EV3ButtonConst, type: EV3ButtonType) {
		self.button = button
		self.type = type
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiButton.rawValue)
		mutableData.appendUInt8(type.rawValue)
		mutableData.appendUInt8(button.rawValue)

		return mutableData
	}
}
