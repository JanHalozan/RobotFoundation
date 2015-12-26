//
//  EV3ListingResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListingResponse: MindstormsResponse {
	public let length: UInt16
	public let replyType: EV3ReplyType
	public let messageCounter: UInt16

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
		self.replyType = replyType
		self.messageCounter = messageCounter

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6))!
		self.listSize = data.readUInt32AtIndex(7)
		self.handle = data.readUInt8AtIndex(11)
		
		let toEnd = data.length - 12
		var stringBuffer = [Int8](count: toEnd, repeatedValue: 0)
		data.getBytes(&stringBuffer, range: NSMakeRange(12, toEnd))

		self.string = NSString(UTF8String: stringBuffer) as! String
	}
}

public struct EV3ContinueListingResponse: MindstormsResponse {
	public let length: UInt16
	public let replyType: EV3ReplyType
	public let messageCounter: UInt16

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let string: String

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.replyType = replyType
		self.messageCounter = messageCounter

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6))!
		self.handle = data.readUInt8AtIndex(7)

		let toEnd = data.length - 8
		var stringBuffer = [Int8](count: toEnd, repeatedValue: 0)
		data.getBytes(&stringBuffer, range: NSMakeRange(8, toEnd))

		self.string = NSString(UTF8String: stringBuffer) as! String
	}
}
