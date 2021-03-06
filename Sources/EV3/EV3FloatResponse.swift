//
//  EV3FloatResponse.swift
//  RobotFoundation
//
//  Created by Matt on 6/3/16.
//

import Foundation

public struct EV3FloatResponse: EV3Response {
	public let value: Float

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		value = data.readFloatAtIndex(0)
		responseLength = 4
	}
}

