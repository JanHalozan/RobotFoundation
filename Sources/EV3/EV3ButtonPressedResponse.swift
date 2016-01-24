//
//  EV3ButtonPressedResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3ButtonPressedResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let pressed: Bool

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			assertionFailure()
			return nil
		}

		self.length = length
		self.replyType = replyType
		self.messageCounter = messageCounter

		self.pressed = data.readUInt8AtIndex(5) > 0 ? true : false
	}
}
