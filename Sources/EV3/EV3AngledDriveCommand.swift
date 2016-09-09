//
//  EV3AngledDriveCommand.swift
//  RobotFoundation
//
//  Created by Matt on 7/10/16.
//

import Foundation

public struct EV3AngledDriveCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions
	public let speed: Int8 // -100 to 100
	public let turnRatio: Int16 // -200 to 200
	public let angle: UInt32 // in degrees, e.g. one rotation = 360
	public let shouldBrakeWhenDone: Bool

	public init(ports: EV3OutputPortOptions, speed: Int8, turnRatio: Int16, angle: UInt32, shouldBrakeWhenDone: Bool) {
		self.ports = ports
		self.speed = speed
		self.turnRatio = turnRatio
		self.angle = angle
		self.shouldBrakeWhenDone = shouldBrakeWhenDone
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputStepSync.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendLC1(unsafeBitCast(speed, to: UInt8.self))
		mutableData.appendLC2(unsafeBitCast(turnRatio, to: UInt16.self))
		mutableData.appendLC4(angle)
		mutableData.appendInt8(shouldBrakeWhenDone ? 1 : 0)

		return mutableData
	}
}
