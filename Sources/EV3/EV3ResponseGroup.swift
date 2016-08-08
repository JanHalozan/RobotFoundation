//
//  EV3ResponseGroup.swift
//  RobotFoundation
//
//  Created by Matt on 5/23/16.
//

import Foundation

/// Consists of one EV3Response which can be accessed via `firstResponse` for individual commands.
/// Consists of one or more EV3Responses for command groups.
public struct EV3ResponseGroup {
	public let length: UInt16
	public let messageCounter: UInt16

	public let responses: [EV3Response]

	public var firstResponse: EV3Response {
		return responses[0]
	}

	public init(length: UInt16, messageCounter: UInt16, responses: [EV3Response]) {
		self.length = length
		self.messageCounter = messageCounter
		self.responses = responses
	}
}
