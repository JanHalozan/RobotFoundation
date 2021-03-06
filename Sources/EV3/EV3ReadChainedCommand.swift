//
//  EV3OpenReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

private let kBatchLength = 768

public struct EV3ReadChainedCommand: EV3DirectCommand {
	public let path: String
	public let offset: UInt16
	public let bytesToRead: UInt16

	public init(path: String, offset: UInt16, bytesToRead: UInt16) {
		self.path = path
		self.offset = offset
		self.bytesToRead = bytesToRead
	}

	public var responseInfo: [String: Any] {
		return [kResponseMaxLengthKey: Int(bytesToRead)]
	}

	public var responseType: MindstormsResponse.Type {
		return EV3HandleDataResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return bytesToRead + 4
	}

	public func payloadDataWithGlobalOffset(_ globalOffset: UInt16) -> Data {
		var mutableData = Data()

		// Open read
		mutableData.appendUInt8(EV3OpCode.file.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.openRead.rawValue)
		mutableData.appendLCS(path)

		// Handle is in GV(0)
		mutableData.appendGV2(globalOffset)
		mutableData.appendGV2(globalOffset + 4)

		for x in stride(from: Int(offset), to: 0, by: -kBatchLength) {
			mutableData.appendUInt8(EV3OpCode.file.rawValue)
			mutableData.appendUInt8(EV3FileOpSubcode.readBytes.rawValue)
			mutableData.appendGV2(globalOffset)
			mutableData.appendLC2(UInt16(x > kBatchLength ? kBatchLength : x))
			mutableData.appendGV2(globalOffset + 4)
		}

		// Read bytes
		mutableData.appendUInt8(EV3OpCode.file.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.readBytes.rawValue)
		mutableData.appendGV2(globalOffset)
		mutableData.appendLC2(bytesToRead)
		mutableData.appendGV2(globalOffset + 4)

		// Close
		mutableData.appendUInt8(EV3OpCode.file.rawValue)
		mutableData.appendUInt8(EV3FileOpSubcode.close.rawValue)
		mutableData.appendGV2(globalOffset)

		return mutableData
	}
}
