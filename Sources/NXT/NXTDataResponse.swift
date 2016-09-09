//
//  NXTDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTDataResponse: NXTResponse {
	public let status: NXTStatus
	public let handle: UInt8
	public let size: UInt16
	public let contents: Data

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)
		self.size = payloadData.readUInt16AtIndex(1)
		self.contents = payloadData.subdata(in: 3..<(Int(size)+3))
		assert(Int(self.size) <= payloadData.count - 3)
	}
}
