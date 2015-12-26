//
//  EV3StringResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3StringResponse: MindstormsResponse {
	let length: UInt16
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	public let string: String

	public init?(data: NSData) {
		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.length = length
		self.replyType = replyType
		self.messageCounter = messageCounter

		let toEnd = data.length - 5
		var string = [Int8](count: toEnd, repeatedValue: 0)
		data.getBytes(&string, range: NSMakeRange(5, toEnd))

		self.string = NSString(UTF8String: string) as! String
	}
}
