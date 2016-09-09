//
//  EV3ReadFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

public struct EV3ReadFileCommand: EV3SystemCommand {
	public let path: String
	public let bytesToRead: UInt16

	public init(path: String, bytesToRead: UInt16) {
		self.path = path
		self.bytesToRead = bytesToRead
	}

	public var responseType: MindstormsResponse.Type {
		return EV3FileResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x94
	}

	public var responseInfo: [String : Any] {
		return [kEV3FileLengthInfo: Int(bytesToRead)]
	}

	public var payloadData: Data {
		var mutableData = Data()
		mutableData.appendUInt16(bytesToRead)
		mutableData.appendString(path)

		return mutableData
	}
}


public struct EV3ContinueReadFileCommand: EV3SystemCommand {
	public let handle: UInt8
	public let bytesToRead: UInt16

	public init(handle: UInt8, bytesToRead: UInt16) {
		self.handle = handle
		self.bytesToRead = bytesToRead
	}

	public var responseType: MindstormsResponse.Type {
		return EV3ContinueFileResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x95
	}

	public var responseInfo: [String : Any] {
		return [kEV3FileLengthInfo: Int(bytesToRead)]
	}

	public var payloadData: Data {
		var mutableData = Data()
		mutableData.appendUInt8(handle)
		mutableData.appendUInt16(bytesToRead)

		return mutableData
	}
}
