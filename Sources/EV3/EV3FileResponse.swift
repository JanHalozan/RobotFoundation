//
//  EV3FileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

// TODO: This is really similar to the listing response
public struct EV3FileResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let fileSize: UInt32
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			assertionFailure()
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6)) ?? EV3SystemReturnStatus.UnknownError
		self.fileSize = data.readUInt32AtIndex(7)
		self.handle = data.readUInt8AtIndex(11)

		let toEnd = Int(length) - 10 // size (2 bytes) not included
		self.data = data.subdataWithRange(NSMakeRange(12, toEnd))
	}
}


public struct EV3HandleResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let handle: UInt8

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			assertionFailure()
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.handle = data.readUInt8AtIndex(5)
	}
}


public struct EV3ContinueFileResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6)) ?? EV3SystemReturnStatus.UnknownError
		self.handle = data.readUInt8AtIndex(7)

		let toEnd = Int(length) - 6 // size (2 bytes) not included
		self.data = data.subdataWithRange(NSMakeRange(8, toEnd))
	}
}
