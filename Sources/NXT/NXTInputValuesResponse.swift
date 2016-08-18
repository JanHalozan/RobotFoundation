//
//  NXTInputValuesResponse.swift
//  RobotFoundation
//
//  Created by Matt on 8/17/16.
//

import Foundation

public struct NXTInputValuesResponse: NXTResponse {
	public let status: NXTStatus
	public let scaledValue: Int?

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		if payloadData.readUInt8AtIndex(1) == 1 /* is valid */ {
			scaledValue = Int(payloadData.readUInt16AtIndex(9))
		} else {
			scaledValue = nil
		}
	}
}
