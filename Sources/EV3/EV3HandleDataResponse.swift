//
//  EV3HandleDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/25/15.
//

import Foundation

public struct EV3HandleDataResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let handle: UInt32
	public let data: NSData

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.handle = data.readUInt32AtIndex(5)

		let toEnd = Int(length) - 7 // size (2 bytes) not included
		self.data = data.subdataWithRange(NSMakeRange(9, toEnd))
	}
}
