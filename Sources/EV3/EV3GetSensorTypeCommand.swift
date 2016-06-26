//
//  EV3GetSensorTypeCommand.swift
//  RobotFoundation
//
//  Created by Matt on 6/26/16.
//

import Foundation

public struct EV3GetSensorTypeCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3SensorTypeModeResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 2
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputDevice.rawValue)
		mutableData.appendUInt8(EV3InputDeviceOpSubcode.GetTypeMode.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendGV2(offset)
		mutableData.appendGV2(offset + 1)

		return mutableData.copy() as! NSData
	}
}
