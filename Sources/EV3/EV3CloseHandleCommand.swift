//
//  EV3CloseHandleCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/8/16.
//

import Foundation

public struct EV3CloseHandleCommand: EV3SystemCommand {
	public let handle: UInt8

	public init(handle: UInt8) {
		self.handle = handle
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x98
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(handle)

		return mutableData.copy() as! NSData
	}
}
