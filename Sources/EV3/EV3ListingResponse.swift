//
//  EV3ListingResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListingResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let listSize: UInt32
	public let handle: UInt8

	public let string: String

	public init?(data: NSData, userInfo: [String : Any]) {
		self.systemCommand = data.readUInt8AtIndex(0)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.UnknownError
		self.listSize = data.readUInt32AtIndex(2)
		self.handle = data.readUInt8AtIndex(6)
		self.string = data.readStringAtIndex(7, length: Int(listSize))
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

	public init?(data: NSData, userInfo: [String : Any]) {
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
