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

	public var responseInfo: [String : Any] {
		return [kResponseMaxLengthKey: Int(kEV3MaxSensorNameLength)]
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.inputDevice.rawValue)
		mutableData.appendUInt8(EV3InputDeviceOpSubcode.getName.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}

