//
//  EV3ReadTouchSensorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

// 1 if on, 0 if off.
private let kEV3TouchSensorBooleanMode = UInt8(0)

public struct EV3ReadTouchSensorCommand: EV3DirectCommand {
	public let port: EV3RawInputPort

	public init(port: EV3RawInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3BooleanSensorResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.inputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.keepType.rawValue)
		mutableData.appendUInt8(kEV3TouchSensorBooleanMode)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
