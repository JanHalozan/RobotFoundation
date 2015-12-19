//
//  NXTResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

typealias NXTResponseHandler = NXTResponse -> ()

protocol NXTResponse: CustomDebugStringConvertible {
	init?(data: NSData)

	var status: NXTStatus { get }
}

extension NXTResponse {
	var debugDescription: String {
		return "MRNXTResponse [status=\(status)]"
	}
}

extension NXTStatus {
	init?(responseData: NSData) {
		let headerData = responseData.subdataWithRange(NSMakeRange(2, 3))

		var status = NXTStatus.UndefinedError
		headerData.getBytes(&status, range: NSMakeRange(2, 1))

		self = status
	}
}

extension NSData {
	var payloadData: NSData? {
		guard length > 3 else {
			return nil
		}

		return subdataWithRange(NSMakeRange(5, length - 5))
	}
}
