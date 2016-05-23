//
//  EV3DisplayRestorationCommands.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3StoreCommand: EV3DirectCommand {
	private let level: UInt8

	public init(level: UInt8) {
		self.level = level
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Store.rawValue)
		mutableData.appendUInt8(level)

		return mutableData.copy() as! NSData
	}
}

public struct EV3RestoreCommand: EV3DirectCommand {
	private let level: UInt8

	// Pass 0 to restore the screen just before run
	public init(level: UInt8) {
		self.level = level
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Restore.rawValue)
		mutableData.appendUInt8(level)

		return mutableData.copy() as! NSData
	}
}
