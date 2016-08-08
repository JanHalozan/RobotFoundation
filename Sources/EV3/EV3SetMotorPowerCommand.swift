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

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputPower.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(power, UInt8.self))

		return mutableData.copy() as! NSData
	}
}
