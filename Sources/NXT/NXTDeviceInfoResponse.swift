//
//  NXTDeviceInfoResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTDeviceInfoResponse: NXTResponse {
	let status: NXTStatus

	let brickName: String
	let freeSpace: UInt32 // bytes

	init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		let nameData = payloadData.subdataWithRange(NSMakeRange(0, 15))
		brickName = NSString(data: nameData, encoding: NSUTF8StringEncoding)! as String

		self.freeSpace = payloadData.readUInt32AtIndex(26)
	}
}
