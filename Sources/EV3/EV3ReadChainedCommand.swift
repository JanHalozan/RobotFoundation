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

	public var payloadData: NSData {
		let mutableData = NSMutableData()

		// Open read
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.OpenRead.rawValue)

		mutableData.appendUInt8(0x84)
		mutableData.appendString(path)

		// Handle is in GV(0)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar4.rawValue)

		for var x = Int(offset); x > 0; x -= 1000 {
			mutableData.appendUInt8(EV3OpCode.File.rawValue)
			mutableData.appendUInt8(EV3FileOpSubcode.ReadBytes.rawValue)
			mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
			mutableData.appendLC2(UInt16(x > 1000 ? 1000 : x))
			mutableData.appendUInt8(EV3Variables.GlobalVar4.rawValue)
		}

		// Read bytes
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.ReadBytes.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
		mutableData.appendLC2(bytesToRead)
		mutableData.appendUInt8(EV3Variables.GlobalVar4.rawValue)

		// Close
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.Close.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
