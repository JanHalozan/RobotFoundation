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


public struct EV3ContinueListFilesCommand: EV3SystemCommand {
	public let handle: UInt8

	public init(handle: UInt8) {
		self.handle = handle
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ContinueListingResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x9A
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()

		mutableData.appendUInt8(handle)

		// max bytes to read
		// apparently 1000 is the max bytes we can read from a file list
		mutableData.appendUInt16(1000)

		return mutableData.copy() as! NSData
	}
}
