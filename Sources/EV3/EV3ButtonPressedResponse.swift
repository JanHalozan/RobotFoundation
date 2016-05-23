//
//  EV3ButtonPressedResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3ButtonPressedResponse: EV3Response {
	public let pressed: Bool

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		self.pressed = data.readUInt8AtIndex(0) > 0 ? true : false
		responseLength = 1
	}
}
