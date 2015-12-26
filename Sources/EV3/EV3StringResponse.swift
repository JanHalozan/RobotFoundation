//
//  EV3StringResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3StringResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let string: String

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.string = data.readStringAtIndex(5, length: Int(length) - 3)
	}
}
