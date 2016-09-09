//
//  EV3ReadColorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3ReadColorCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ColorResponse.self
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
		mutableData.appendUInt8(2)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
