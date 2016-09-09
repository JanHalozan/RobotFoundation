//
//  EV3ColorResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public enum EV3SensorColor: UInt32 {
	case none = 0, black, blue, green, yellow, red, white, brown
}

public struct EV3ColorResponse: EV3Response {
	public let color: EV3SensorColor

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		let index = data.readFloatAtIndex(0)
		if index.isNaN || index.isInfinite {
			color = .none
		} else {
			color = EV3SensorColor(rawValue: UInt32(Int(index))) ?? EV3SensorColor.none
		}
		responseLength = 4
	}
}
