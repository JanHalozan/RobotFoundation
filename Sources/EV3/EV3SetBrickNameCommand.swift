//
//  EV3SetBrickNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/28/16.
//

import Foundation

public struct EV3SetBrickNameCommand: EV3DirectCommand {
	public let name: String

	public init(name: String) {
		self.name = name
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.COMSet.rawValue)
		mutableData.appendUInt8(EV3COMSetSubcode.SetBrickName.rawValue)
		mutableData.appendUInt8(0x84)
		mutableData.appendString(name)

		return mutableData.copy() as! NSData
	}
}
