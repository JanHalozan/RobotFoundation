//
//  EV3SetSensorModeCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3SetSensorModeCommand: EV3DirectCommand {
	public let port: EV3RawInputPort
	public let mode: UInt8

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.inputReadSI.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(0)
		mutableData.appendUInt8(mode)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
