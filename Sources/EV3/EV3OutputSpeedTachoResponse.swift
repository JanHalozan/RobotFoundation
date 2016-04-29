//
//  EV3OutputSpeedTachoResponse.swift
//  RobotFoundation
//
//  Created by Matt on 4/28/16.
//

import Foundation

public struct EV3OutputSpeedTachoResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let speed: Int8
	public let tacho: UInt32

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.messageCounter = messageCounter
		self.replyType = replyType

		self.speed = data.readInt8AtIndex(5)
		self.tacho = data.readUInt32AtIndex(6)
	}
}
