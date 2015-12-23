//
//  EV3ListFilesCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListFilesCommand: EV3SystemCommand {
	public let path: String

	public init(path: String) {
		self.path = path
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ListingResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x99
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()

		// max bytes to read
		// apparently 1000 is the max bytes we can read from a file list
		mutableData.appendUInt16(1000)
		mutableData.appendString(path)

		return mutableData.copy() as! NSData
	}
}
