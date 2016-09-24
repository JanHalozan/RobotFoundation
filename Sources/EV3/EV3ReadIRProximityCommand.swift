//
//  EV3ReadIRProximityCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/22/16.
//

import Foundation

private let kEV3IRSensorProximityMode = UInt8(0)

public struct EV3ReadIRProximityCommand: EV3DirectCommand {
	public let port: EV3RawInputPort

	public init(port: EV3RawInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3PercentByteResponse.self
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
		mutableData.appendUInt8(kEV3IRSensorProximityMode)
		mutableData.appendGV2(offset)

		return mutableData
	}
}

