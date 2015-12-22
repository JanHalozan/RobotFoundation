//
//  EV3StringResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

struct EV3StringResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let string: String

	init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		let toEnd = data.length - 5
		var string = [Int8](count: toEnd, repeatedValue: 0)
		data.getBytes(&string, range: NSMakeRange(5, toEnd))

		self.string = NSString(UTF8String: string) as! String
	}
}
