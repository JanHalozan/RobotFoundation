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

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.sound.rawValue)
		mutableData.appendUInt8(EV3SoundOpSubcode.break.rawValue)

		return mutableData
	}
}
