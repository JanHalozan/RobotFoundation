//
//  EV3OpenReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

public struct EV3ReadChainedCommand: EV3DirectCommand {
	public let path: String
	public let offset: UInt16
	public let bytesToRead: UInt16

	public init(path: String, offset: UInt16, bytesToRead: UInt16) {
		self.path = path
		self.offset = offset
		self.bytesToRead = bytesToRead
	}

	public var responseType: MindstormsResponse.Type {
		return EV3HandleDataResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return bytesToRead + 4
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()

		// Open read
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.OpenRead.rawValue)

		mutableData.appendUInt8(0x84)
		mutableData.appendString(path)

		// Handle is in GV(0)
		mutableData.appendGV2(offset)
		mutableData.appendGV2(offset + 4)

		for x in Int(offset).stride(to: 0, by: -1000) {
			mutableData.appendUInt8(EV3OpCode.File.rawValue)
			mutableData.appendUInt8(EV3FileOpSubcode.ReadBytes.rawValue)
			mutableData.appendGV2(offset)
			mutableData.appendLC2(UInt16(x > 1000 ? 1000 : x))
			mutableData.appendGV2(offset + 4)
		}

		// Read bytes
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.ReadBytes.rawValue)
		mutableData.appendGV2(offset)
		mutableData.appendLC2(bytesToRead)
		mutableData.appendGV2(offset + 4)

		// Close
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.Close.rawValue)
		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}
