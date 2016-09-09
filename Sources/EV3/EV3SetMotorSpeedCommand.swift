//
//  EV3SetMotorSpeedCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3SetMotorSpeedCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions
	public let speed: Int8

	public init(ports: EV3OutputPortOptions, speed: Int8) {
		self.ports = ports
		self.speed = speed
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputSpeed.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(speed, to: UInt8.self))

		return mutableData
	}
}
