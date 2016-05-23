//
//  EV3ColorResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public enum EV3SensorColor: UInt8 {
	case None = 0, Black, Blue, Green, Yellow, Red, White, Brown
}

public struct EV3ColorResponse: EV3Response {
	public let color: EV3SensorColor

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		let index = data.readUInt8AtIndex(0)
		self.color = EV3SensorColor(rawValue: index) ?? EV3SensorColor.None
		responseLength = 1
	}
}
