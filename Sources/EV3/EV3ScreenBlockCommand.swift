//
//  EV3ScreenBlockCommand.swift
//  RobotFoundation
//
//  Created by Matt on 8/15/16.
//

import Foundation

public struct EV3ScreenBlockCommand: EV3DirectCommand {
	private let block: Bool

	public init(block: Bool) {
		self.block = block
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIWrite.rawValue)
		mutableData.appendUInt8(EV3UIWriteOpSubcode.ScreenBlock.rawValue)
		mutableData.appendUInt8(block ? 1 : 0)

		return mutableData.copy() as! NSData
	}
}
