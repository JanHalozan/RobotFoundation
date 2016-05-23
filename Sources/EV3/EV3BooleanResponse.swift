//
//  EV3BooleanResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/30/16.
//

import Foundation

public struct EV3BooleanResponse: EV3Response {
	public let value: Bool

	public init?(data: NSData, userInfo: [String : Any]) {
		self.value = data.readUInt8AtIndex(0) == 1 ? true : false
	}
}
