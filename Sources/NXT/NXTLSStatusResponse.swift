//
//  NXTLSStatusResponse.swift
//  RobotFoundation
//
//  Created by Matt on 9/7/16.
//

import Foundation

public struct NXTLSStatusResponse: NXTResponse {
	public let status: NXTStatus
	public let bytesReady: UInt8

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		bytesReady = payloadData.readUInt8AtIndex(0)
	}
}
