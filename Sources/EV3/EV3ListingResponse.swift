//
//  EV3ListingResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListingResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let systemCommand: UInt8
	let returnStatus: UInt8
	let listSize: UInt32
	let handle: UInt8

	public let entries: [EV3Entry]

	public init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		self.systemCommand = data.readUInt8AtIndex(5)
		self.returnStatus = data.readUInt8AtIndex(6)
		self.listSize = data.readUInt32AtIndex(7)
		self.handle = data.readUInt8AtIndex(11)
		
		let toEnd = data.length - 12
		var stringBuffer = [Int8](count: toEnd, repeatedValue: 0)
		data.getBytes(&stringBuffer, range: NSMakeRange(12, toEnd))

		let string = NSString(UTF8String: stringBuffer) as! String
		self.entries = entriesForListingString(string)
	}
}
