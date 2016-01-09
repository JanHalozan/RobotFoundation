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

	public var payloadData: NSData {
		let mutableData = NSMutableData()

		// Open write
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(type.rawValue)

		mutableData.appendUInt8(0x84)
		mutableData.appendString(path)

		// Handle is in GV(0)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		// Write bytes, one at a time (unfortunately)
		for offset in 0..<data.length {
			mutableData.appendUInt8(EV3OpCode.File.rawValue)
			mutableData.appendUInt8(EV3FileOpSubcode.WriteBytes.rawValue)
			mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)
			mutableData.appendLC2(1)
			mutableData.appendLC1(data.readUInt8AtIndex(offset))
		}

		// Close
		mutableData.appendUInt8(EV3OpCode.File.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.Close.rawValue)
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
