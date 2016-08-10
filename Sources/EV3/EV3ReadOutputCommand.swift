//
//  EV3ReadOutputCommand.swift
//  RobotFoundation
//
//  Created by Matt on 4/28/16.
//

import Foundation

public struct EV3ReadOutputCommand: EV3DirectCommand {
	public let port: EV3OutputPort

	public init(port: EV3OutputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return EV3OutputSpeedTachoResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 5
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.OutputRead.rawValue)
		mutableData.appendUInt8(EV3Layer.ThisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)

		mutableData.appendGV2(offset)
		mutableData.appendGV2(offset + 4)

		return mutableData.copy() as! NSData
	}
}

