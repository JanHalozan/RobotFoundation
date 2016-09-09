//
//  EV3SetMotorPowerCommand.swift
//  RobotFoundation
//
//  Created by Matt on 2/13/16.
//

import Foundation

public struct EV3SetMotorPowerCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions
	public let power: Int8

	public init(ports: EV3OutputPortOptions, power: Int8) {
		self.ports = ports
		self.power = power
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputPower.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(power, to: UInt8.self))

		return mutableData
	}
}
