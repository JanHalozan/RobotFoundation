//
//  NXTHandleResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

struct NXTHandleResponse: NXTResponse {
	let status: NXTStatus
	let handle: UInt8

	init?(data: NSData, userInfo: [String : Any]) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)
	}
}
