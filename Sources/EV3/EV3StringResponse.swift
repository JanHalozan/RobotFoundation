//
//  EV3StringResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

let kResponseMaxLengthKey = "maxLength"

public struct EV3StringResponse: EV3Response {
	public let string: String

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let maxLength = userInfo[kResponseMaxLengthKey] as? Int else {
			assertionFailure()
			return nil
		}
		
		// Will stop at NULL terminator.
		string = data.readStringOfUnknownLengthAtIndex(0, maxLength: maxLength)
		responseLength = maxLength
	}
}
