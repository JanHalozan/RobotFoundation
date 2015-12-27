//
//  EV3StorageResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/27/15.
//

import Foundation

public struct EV3StorageResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let totalSize: UInt32
	public let freeSize: UInt32

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.totalSize = data.readUInt32AtIndex(5)
		self.freeSize = data.readUInt32AtIndex(9)
	}
}
