//
//  EV3GetSensorTypeCommand.swift
//  RobotFoundation
//
//  Created by Matt on 6/26/16.
//

import Foundation

public struct EV3GetSensorTypeCommand: EV3DirectCommand {
	public let port: EV3RawInputPort

	public init(port: EV3RawInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3SensorTypeModeResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 2
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.inputDevice.rawValue)
		mutableData.appendUInt8(EV3InputDeviceOpSubcode.getTypeMode.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendGV2(offset)
		mutableData.appendGV2(offset + 1)

		return mutableData
	}
}
