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

	init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		var handle = UInt8()
		payloadData.getBytes(&handle, range: NSMakeRange(0, 1))

		self.handle = handle
	}
}
