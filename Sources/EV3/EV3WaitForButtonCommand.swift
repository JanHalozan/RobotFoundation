//
//  EV3WaitForButtonCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3WaitForButtonCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiButton.rawValue)
		mutableData.appendUInt8(EV3ButtonOpSubcode.waitForPress.rawValue)

		return mutableData
	}
}
