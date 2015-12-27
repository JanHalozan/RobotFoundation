//
//  EV3GetFWVersionCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/27/15.
//

import Foundation

public enum EV3Version: UInt8 {
	case OS = 3
	case Hardware = 9
	case Firmware = 10
	case FirmwareBuild = 11
	case OSBuild = 12
}

public struct EV3GetVersionCommand: EV3DirectCommand {
	public let version: EV3Version

	public init(version: EV3Version) {
		self.version = version
	}

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return EV3MaxFileLength
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIRead.rawValue)
		mutableData.appendUInt8(version.rawValue)
		mutableData.appendLC2(UInt16(EV3MaxFileLength))
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
