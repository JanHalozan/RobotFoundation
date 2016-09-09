//
//  EV3FileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

let kEV3FileLengthInfo = "response.file.length.info"

// FIXME: This is really similar to the listing response
public struct EV3FileResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let fileSize: UInt32
	public let handle: UInt8

	public let data: Data

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		guard data.count >= 7 else {
			// Otherwise we don't even have the whole metadata!
			assertionFailure()
			return nil
		}

		guard let length = userInfo[kEV3FileLengthInfo] as? Int else {
			assertionFailure()
			return nil
		}

		let retrievedLength = data.count - 7
		guard retrievedLength <= length else {
			assertionFailure()
			return nil
		}

		systemCommand = data.readUInt8AtIndex(0)
		returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.unknownError
		fileSize = data.readUInt32AtIndex(2)
		handle = data.readUInt8AtIndex(6)
		self.data = data.subdata(in: 7..<(7+retrievedLength))
		responseLength = data.count

		// The chunk of data we just read shouldn't exceed the total file size.
		assert(retrievedLength <= Int(fileSize))
	}
}


public struct EV3HandleResponse: EV3Response {
	public let handle: UInt8

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		handle = data.readUInt8AtIndex(0)
		responseLength = 1
	}
}


public struct EV3ContinueFileResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let data: Data

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		guard let length = userInfo[kEV3FileLengthInfo] as? Int else {
			assertionFailure()
			return nil
		}

		guard length <= data.count - 3 else {
			assertionFailure()
			return nil
		}

		systemCommand = data.readUInt8AtIndex(0)
		returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.unknownError
		handle = data.readUInt8AtIndex(2)
		self.data = data.subdata(in: 3..<(3+length))
		responseLength = 3 + length
	}
}
