//
//  EV3HandleDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/25/15.
//

import Foundation

public struct EV3HandleDataResponse: MindstormsResponse {
	public let replyType: EV3ReplyType
	public let messageCounter: UInt16

	public let handle: UInt32
	public let data: NSData

	public init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter

		self.handle = data.readUInt32AtIndex(5)

		let toEnd = data.length - 9
		self.data = data.subdataWithRange(NSMakeRange(9, toEnd))
	}
}
