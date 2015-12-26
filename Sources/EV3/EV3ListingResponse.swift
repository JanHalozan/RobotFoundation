//
//  EV3ListingResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListingResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let listSize: UInt32
	public let handle: UInt8

	public let string: String

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6)) ?? EV3SystemReturnStatus.UnknownError
		self.listSize = data.readUInt32AtIndex(7)
		self.handle = data.readUInt8AtIndex(11)
		self.string = data.readStringAtIndex(12, length: Int(length) - 10)
	}
}

public struct EV3ContinueListingResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let string: String

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
		self.string = data.readStringAtIndex(8, length: Int(length) - 6)
	}
}
