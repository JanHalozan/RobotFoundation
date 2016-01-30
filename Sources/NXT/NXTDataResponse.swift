//
//  NXTDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTDataResponse: NXTResponse {
	let status: NXTStatus
	let handle: UInt8
	let size: UInt16
	let contents: NSData

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
		self.contents = payloadData.subdataWithRange(NSMakeRange(3, payloadData.length - 3))
	}
}