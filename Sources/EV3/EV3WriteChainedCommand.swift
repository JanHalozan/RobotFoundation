//
//  EV3WriteChainedCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/8/16.
//

import Foundation

public enum EV3WriteChainedType: UInt8 {
	case Append = 0
	case Write = 2
}

public struct EV3WriteChainedCommand: EV3DirectCommand {
	public let path: String
	public let data: NSData
	public let type: EV3WriteChainedType

	public init(path: String, data: NSData, type: EV3WriteChainedType) {
		self.path = path
		self.data = data
		self.type = type
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 2
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()

		// Open write
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(type.rawValue)
		mutableData.appendLCS(path)

		// Handle is in GV(0)
		mutableData.appendGV2(offset)

		// Write bytes, one at a time (unfortunately)
		for i in 0..<data.length {
			mutableData.appendUInt8(EV3OpCode.File.rawValue)
			mutableData.appendUInt8(EV3FileOpSubcode.WriteBytes.rawValue)
			mutableData.appendGV2(offset)
			mutableData.appendLC2(1)
			mutableData.appendLC1(data.readUInt8AtIndex(i))
		}

		// Close
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.Close.rawValue)
		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}
