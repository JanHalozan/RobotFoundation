//
//  NXTLSReadResponse.swift
//  RobotFoundation
//
//  Created by Matt on 9/7/16.
//

import Foundation

public struct NXTLSReadResponse: NXTResponse {
	public let status: NXTStatus
	public let bytesRead: UInt8
	public let rxData: Data

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		bytesRead = payloadData.readUInt8AtIndex(0)

		// Responses are always 16 bytes and padded.
		rxData = payloadData.subdata(in: 1..<17)
	}
}
