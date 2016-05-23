//
//  EV3GetStorageInfoCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/27/15.
//

import Foundation

public struct EV3GetStorageInfoCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3StorageResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 8
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.MemoryUsage.rawValue)
		mutableData.appendUInt8(offset)
		mutableData.appendUInt8(offset + 4)

		return mutableData.copy() as! NSData
	}
}
