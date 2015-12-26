//
//  EV3ColorResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

enum EV3Color: UInt8 {
	case None = 0, Black, Blue, Green, Yellow, Red, White, Brown
}

struct EV3ColorResponse: MindstormsResponse {
	let length: UInt16
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let color: EV3Color

	init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.replyType = replyType
		self.messageCounter = messageCounter

		var index = UInt8()
		data.getBytes(&index, range: NSMakeRange(5, 1))

		self.color = EV3Color(rawValue: index) ?? EV3Color.None
	}
}
