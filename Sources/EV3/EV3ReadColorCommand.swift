//
//  EV3ReadColorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3ReadColorCommand: EV3DirectCommand {
	public let port: EV3InputPort

	public init(port: EV3InputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ColorResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 4
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.InputDevice.rawValue)
		mutableData.appendUInt8(EV3InputDeviceOpSubcode.GetRaw.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}
