//
//  EV3GenericResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3HeaderResponse {
	case IncompleteHeader
	case MismatchedLength
	case MalformedReplyType
	case Success(length: UInt16, messageCounter: UInt16, replyType: EV3ReplyType)
}

func processGenericResponseForData(data: NSData) -> EV3HeaderResponse {
	guard data.length >= 2 else {
		// We don't even have enough space to read the length.
		return .IncompleteHeader
	}

	let length = data.readUInt16AtIndex(0)

	// HID transports aren't aware of how much data is actually being sent so `data` is always a 1024 length buffer, hence the inequality.
	guard data.length - 2 >= Int(length) else {
		// We don't have all the data.
		return .MismatchedLength
	}

	let messageCounter = data.readUInt16AtIndex(2)

	guard let replyType = EV3ReplyType(rawValue: data.readUInt8AtIndex(4)) else {
		return .MalformedReplyType
	}

	return .Success(length: length, messageCounter: messageCounter, replyType: replyType)
}

public struct EV3GenericResponse: EV3Response {
	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		// Deliberate no-op.
		responseLength = 0
	}
}
