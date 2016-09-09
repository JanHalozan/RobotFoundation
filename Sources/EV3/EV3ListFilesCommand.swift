//
//  EV3ListFilesCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

// Apparently 1000 is the max bytes we can read from a file list,
// but we read less to avoid the chance of Bluetooth failure.
private let kMaxBytesToRead = UInt16(768)

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

	public var payloadData: Data {
		var mutableData = Data()
		mutableData.appendUInt16(kMaxBytesToRead)
		mutableData.appendString(path)

		return mutableData
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

	public var payloadData: Data {
		var mutableData = Data()
		mutableData.appendUInt8(handle)
		mutableData.appendUInt16(kMaxBytesToRead)

		return mutableData
	}
}
