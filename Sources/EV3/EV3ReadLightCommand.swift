//
//  EV3ReadLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3ReadLightType: UInt8 {
	case Reflected = 0
	case Ambient = 1
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

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(EV3SensorType.KeepType.rawValue)
		mutableData.appendUInt8(lightType.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
