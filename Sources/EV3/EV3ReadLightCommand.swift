//
//  EV3ReadLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3ReadLightType: UInt8 {
	case reflected = 0
	case ambient = 1
}

public struct EV3ReadLightCommand: EV3DirectCommand {
	public let port: EV3InputPort
	public let lightType: EV3ReadLightType

	public init(port: EV3InputPort, lightType: EV3ReadLightType) {
		self.port = port
		self.lightType = lightType
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
		mutableData.appendUInt8(lightType.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
