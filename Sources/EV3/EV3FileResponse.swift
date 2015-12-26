//
//  EV3FileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/24/15.
//

import Foundation

// TODO: This is really similar to the listing response
public struct EV3FileResponse: MindstormsResponse {
	public let replyType: EV3ReplyType
	public let messageCounter: UInt16

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let fileSize: UInt32
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6))!
		self.fileSize = data.readUInt32AtIndex(7)
		self.handle = data.readUInt8AtIndex(11)

		let toEnd = data.length - 12
		self.data = data.subdataWithRange(NSMakeRange(12, toEnd))
	}
}


public struct EV3ContinueFileResponse: MindstormsResponse {
	public let replyType: EV3ReplyType
	public let messageCounter: UInt16

	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let data: NSData

	public init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(6))!
		self.handle = data.readUInt8AtIndex(7)

		let toEnd = data.length - 8
		self.data = data.subdataWithRange(NSMakeRange(8, toEnd))
	}
}
