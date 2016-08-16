//
//  EV3InitRunCommand.swift
//  RobotFoundation
//
//  Created by Matt on 8/15/16.
//

import Foundation

public struct EV3InitRunCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIWrite.rawValue)
		mutableData.appendUInt8(EV3UIWriteOpSubcode.InitRun.rawValue)

		return mutableData.copy() as! NSData
	}
}
