//
//  EV3FileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

let kEV3FileLengthInfo = "response.file.length.info"

// TODO: This is really similar to the listing response
public struct EV3FileResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let fileSize: UInt32
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let length = userInfo[kEV3FileLengthInfo] as? Int else {
			assertionFailure()
			return nil
		}

		guard length <= data.length - 7 else {
			assertionFailure()
			return nil
		}

		systemCommand = data.readUInt8AtIndex(0)
		returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.UnknownError
		fileSize = data.readUInt32AtIndex(2)
		handle = data.readUInt8AtIndex(6)
		self.data = data.subdataWithRange(NSMakeRange(7, length))
	}
}


public struct EV3HandleResponse: EV3Response {
	public let handle: UInt8

	public init?(data: NSData, userInfo: [String : Any]) {
		handle = data.readUInt8AtIndex(0)
	}
}


public struct EV3ContinueFileResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let length = userInfo[kEV3FileLengthInfo] as? Int else {
			assertionFailure()
			return nil
		}

		guard length <= data.length - 3 else {
			assertionFailure()
			return nil
		}

		systemCommand = data.readUInt8AtIndex(0)
		returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.UnknownError
		handle = data.readUInt8AtIndex(2)
		self.data = data.subdataWithRange(NSMakeRange(3, length))
	}
}
