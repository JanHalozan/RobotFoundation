//
//  EV3GetOSVersionCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3GetOSVersionCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return EV3MaxFileLength
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIRead.rawValue)
		mutableData.appendUInt8(EV3UIReadOpSubcode.GetOSVersion.rawValue)
		mutableData.appendLC2(UInt16(EV3MaxFileLength))
		mutableData.appendUInt8(EV3Variables.GlobalVar0.rawValue)

		return mutableData.copy() as! NSData
	}
}
