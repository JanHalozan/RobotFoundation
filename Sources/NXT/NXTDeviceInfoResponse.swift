//
//  NXTDeviceInfoResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTDeviceInfoResponse: NXTResponse {
	public let status: NXTStatus

	public let brickName: String
	public let freeSpace: UInt32 // bytes

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		let nameData = payloadData.subdata(in: 0..<15)
		brickName = String(data: nameData, encoding: .utf8)!

		self.freeSpace = payloadData.readUInt32AtIndex(26)
	}
}
