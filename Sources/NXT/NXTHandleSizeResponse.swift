//
//  NXTHandleSizeResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

struct NXTHandleSizeResponse: NXTResponse {
	let status: NXTStatus
	let handle: UInt8
	let size: UInt16

	init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)
		self.size = payloadData.readUInt16AtIndex(1)
	}
}
