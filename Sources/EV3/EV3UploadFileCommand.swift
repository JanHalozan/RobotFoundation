//
//  EV3UploadFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/8/16.
//

import Foundation

public struct EV3UploadFileCommand: EV3SystemCommand {
	public let path: String
	public let bytesToWrite: UInt32

	public init(path: String, bytesToWrite: UInt32) {
		self.path = path
		self.bytesToWrite = bytesToWrite
	}

	public var responseType: MindstormsResponse.Type {
		return EV3HandleResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x92
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt32(bytesToWrite)
		mutableData.appendString(path)

		return mutableData.copy() as! NSData
	}
}


public struct EV3ContinueUploadFileCommand: EV3SystemCommand {
	public let handle: UInt8
	public let data: NSData

	public init(handle: UInt8, data: NSData) {
		self.handle = handle
		self.data = data
	}

	public var responseType: MindstormsResponse.Type {
		return EV3HandleResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x93
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(handle)
		mutableData.appendData(data)

		return mutableData.copy() as! NSData
	}
}
