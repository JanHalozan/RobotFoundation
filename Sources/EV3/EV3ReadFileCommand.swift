//
//  EV3GetFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

public struct EV3ReadFileCommand: EV3SystemCommand {
	public let path: String

	public init(path: String) {
		self.path = path
	}

	public var responseType: MindstormsResponse.Type {
		return EV3FileResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x94
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


public struct EV3ContinueReadFileCommand: EV3SystemCommand {
	public let handle: UInt8

	public init(handle: UInt8) {
		self.handle = handle
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ContinueFileResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x95
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
