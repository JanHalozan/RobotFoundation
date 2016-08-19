//
//  EV3GenericResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

func processGenericResponseForData(data: NSData) -> (UInt16, UInt16, EV3ReplyType)? {
	guard data.length >= 2 else {
		// We don't even have enough space to read the length.
		return nil
	}

	let length = data.readUInt16AtIndex(0)

	guard data.length - 2 == Int(length) else {
		// We don't have all the data.
		return nil
	}

	let messageCounter = data.readUInt16AtIndex(2)

	guard let replyType = EV3ReplyType(rawValue: data.readUInt8AtIndex(4)) else {
		return nil
	}

	return (length, messageCounter, replyType)
}

public struct EV3GenericResponse: EV3Response {
	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		// Deliberate no-op.
		responseLength = 0
	}
}
