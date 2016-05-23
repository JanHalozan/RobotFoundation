//
//  EV3TimedDriveCommand.swift
//  RobotFoundation
//
//  Created by Matt on 2/13/16.
//

import Foundation

public struct EV3TimedDriveCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions
	public let speed: Int8 // -100 to 100
	public let turnRatio: Int16 // -200 to 200
	public let duration: UInt32 // in ms
	public let shouldBrakeWhenDone: Bool

	public init(ports: EV3OutputPortOptions, speed: Int8, turnRatio: Int16, duration: UInt32, shouldBrakeWhenDone: Bool) {
		self.ports = ports
		self.speed = speed
		self.turnRatio = turnRatio
		self.duration = duration
		self.shouldBrakeWhenDone = shouldBrakeWhenDone
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputTimeSync.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(speed, UInt8.self))
		mutableData.appendLC2(unsafeBitCast(turnRatio, UInt16.self))
		mutableData.appendLC4(duration)
		mutableData.appendInt8(shouldBrakeWhenDone ? 1 : 0)

		return mutableData.copy() as! NSData
	}
}
