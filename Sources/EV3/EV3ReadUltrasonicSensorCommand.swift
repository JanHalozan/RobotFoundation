//
//  EV3ReadUltrasonicSensorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 6/3/16.
//

import Foundation

private let kEV3UltrasonicSensorCMMode = UInt8(0)

public struct EV3ReadUltrasonicSensorCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3FloatResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 4
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputReadSI.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(kEV3UltrasonicSensorCMMode)
		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}

