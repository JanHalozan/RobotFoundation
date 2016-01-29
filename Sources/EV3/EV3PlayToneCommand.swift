//
//  EV3PlayToneCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct EV3PlayToneCommand: EV3DirectCommand {
	public let frequency: UInt16
	public let duration: UInt16 // ms

	public init(frequency: UInt16, duration: UInt16) {
		self.frequency = frequency
		self.duration = duration
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.Sound.rawValue)
		mutableData.appendUInt8(EV3SoundOpSubcode.PlayTone.rawValue)

		// Sound level
		mutableData.appendLC1(0x2)

		mutableData.appendLC2(frequency)
		mutableData.appendLC2(duration)

		return mutableData.copy() as! NSData
	}
}
