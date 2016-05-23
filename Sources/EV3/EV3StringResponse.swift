//
//  EV3StringResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3StringResponse: EV3Response {
	public let string: String

	public init?(data: NSData, userInfo: [String : Any]) {
		// Will stop at NULL terminator.
		self.string = data.readStringOfUnknownLengthAtIndex(0, maxLength: data.length)
	}
}
