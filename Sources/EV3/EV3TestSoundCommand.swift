//
//  EV3TestSoundCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/30/16.
//

import Foundation

public struct EV3TestSoundCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3BooleanResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.soundTest.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
