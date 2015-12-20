//
//  EV3PercentFloatResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct EV3PercentFloatResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let percent: Float

	init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		var percent = Float()
		data.getBytes(&percent, range: NSMakeRange(5, 4))

		self.percent = percent
	}
}
