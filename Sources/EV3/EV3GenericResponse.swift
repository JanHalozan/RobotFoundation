//
//  EV3GenericResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

func processGenericResponseForData(data: NSData) -> (UInt16, EV3ReplyType)? {
	guard data.length >= 2 else {
		// We don't even have enough space to read the length.
		return nil
	}

	let length = data.readUInt16AtIndex(0)

	guard data.length - 2 >= Int(length) else {
		// We don't have all the data.
		return nil
	}

	let messageCounter = data.readUInt16AtIndex(2)

	guard let replyType = EV3ReplyType(rawValue: data.readUInt8AtIndex(4)) else {
		return nil
	}

	return (messageCounter, replyType)
}

struct EV3GenericResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter
	}
}
