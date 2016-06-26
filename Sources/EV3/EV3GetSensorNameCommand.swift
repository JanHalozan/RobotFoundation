//
//  EV3GetSensorNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 6/26/16.
//

import Foundation

private let kEV3MaxSensorNameLength = 255

public struct EV3GetSensorNameCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return UInt16(kEV3MaxSensorNameLength)
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputDevice.rawValue)
		mutableData.appendUInt8(EV3InputDeviceOpSubcode.GetName.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}

