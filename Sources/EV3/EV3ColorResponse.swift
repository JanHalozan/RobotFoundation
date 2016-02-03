//
//  EV3ColorResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public enum EV3SensorColor: UInt8 {
	case None = 0, Black, Blue, Green, Yellow, Red, White, Brown
}

public struct EV3ColorResponse: EV3Response {
	public let length: UInt16
	public let messageCounter: UInt16
	public let replyType: EV3ReplyType

	public let color: EV3SensorColor

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			assertionFailure()
			return nil
		}

		self.length = length
		self.replyType = replyType
		self.messageCounter = messageCounter

		let index = data.readUInt8AtIndex(5)
		self.color = EV3SensorColor(rawValue: index) ?? EV3SensorColor.None
	}
}
