//
//  EV3ListFilesCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListFilesCommand: EV3SystemCommand {
	public let path: String

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x99
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()

		// max bytes to read
		mutableData.appendUInt16(64)

		return mutableData.copy() as! NSData
	}
}
