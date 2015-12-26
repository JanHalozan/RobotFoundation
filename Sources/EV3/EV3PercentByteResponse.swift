//
//  EV3PercentByteResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3PercentByteResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let percent: UInt8

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.percent = data.readUInt8AtIndex(5)
	}
}
