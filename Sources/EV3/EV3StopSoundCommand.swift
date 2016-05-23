//
//  EV3StopSoundCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/30/16.
//

import Foundation

public struct EV3StopSoundCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.Sound.rawValue)
		mutableData.appendUInt8(EV3SoundOpSubcode.Break.rawValue)

		return mutableData.copy() as! NSData
	}
}
