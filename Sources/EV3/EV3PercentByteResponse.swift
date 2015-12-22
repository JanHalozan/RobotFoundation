//
//  EV3PercentByteResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

struct EV3PercentByteResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let percent: UInt8

	init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		var percent = UInt8()
		data.getBytes(&percent, range: NSMakeRange(5, 1))

		self.percent = percent
	}
}