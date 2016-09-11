//
//  EV3ReadGyroCommand.swift
//  RobotFoundation
//
//  Created by Matt on 9/10/16.
//

import Foundation

public enum EV3GyroMode: UInt8 {
	case angle = 0
	case rate = 1
}

public struct EV3ReadGyroCommand: EV3DirectCommand {
	public let port: EV3InputPort
	public let mode: EV3GyroMode

	public init(port: EV3InputPort, mode: EV3GyroMode) {
		self.port = port
		self.mode = mode
	}

	public var responseType: MindstormsResponse.Type {
		return EV3FloatResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 4
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.inputReadSI.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.keepType.rawValue)
		mutableData.appendUInt8(mode.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
