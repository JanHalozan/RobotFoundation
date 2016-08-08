//
//  EV3ScheduleSpeedCommand.swift
//  RobotFoundation
//
//  Created by Matt on 6/22/16.
//

import Foundation

public struct EV3ScheduleSpeedCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions
	public let speed: Int8
	public let time1: UInt32
	public let time2: UInt32
	public let time3: UInt32
	public let stopType: EV3StopType

	public init(ports: EV3OutputPortOptions, speed: Int8, time1: UInt32, time2: UInt32, time3: UInt32, stopType: EV3StopType) {
		self.ports = ports
		self.speed = speed
		self.time1 = time1
		self.time2 = time2
		self.time3 = time3
		self.stopType = stopType
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputTimeSpeed.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(speed, UInt8.self))
		mutableData.appendUInt32(time1)
		mutableData.appendUInt32(time2)
		mutableData.appendUInt32(time3)
		mutableData.appendUInt8(stopType.rawValue)

		return mutableData.copy() as! NSData
	}
}
