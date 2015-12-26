//
//  EV3OpenReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

public struct EV3ReadChainedCommand: EV3DirectCommand {
	public let path: String

	public init(path: String) {
		self.path = path
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1004
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

		// Read bytes
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.ReadBytes.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
		mutableData.appendLC2(1000)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		// Close
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.Close.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
