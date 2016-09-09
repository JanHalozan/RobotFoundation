//
//  EV3HandleDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/25/15.
//

import Foundation

public struct EV3HandleDataResponse: EV3Response {
	public let handle: UInt32
	public let data: Data

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		guard let maxLength = userInfo[kResponseMaxLengthKey] as? Int else {
			assertionFailure()
			return nil
		}

		self.handle = data.readUInt32AtIndex(0)
		self.data = data.subdata(in: 4..<(maxLength+4))

		responseLength = maxLength + 4
	}
}
