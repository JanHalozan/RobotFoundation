//
//  NXTIOMapResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

struct NXTIOMapResponse: NXTResponse {
	let status: NXTStatus
	let module: UInt32
	let bytesRead: UInt16
	let contents: NSData

	init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.module = payloadData.readUInt32AtIndex(0)
		self.bytesRead = payloadData.readUInt16AtIndex(4)
		self.contents = payloadData.subdataWithRange(NSMakeRange(6, Int(bytesRead)))
	}
}
