//
//  NXTResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public protocol NXTResponse: MindstormsResponse, CustomDebugStringConvertible {
	var status: NXTStatus { get }
}

extension NXTResponse {
	public var debugDescription: String {
		return "MRNXTResponse [status=\(status)]"
	}
}

private let kNXTHeaderLength = 3

extension NXTStatus {
	init?(responseData: NSData) {
		let headerData = responseData.subdataWithRange(NSMakeRange(0, kNXTHeaderLength))

		var status = NXTStatus.UndefinedError
		headerData.getBytes(&status, range: NSMakeRange(2, 1))

		self = status
	}
}

extension NSData {
	var payloadData: NSData? {
		guard length >= kNXTHeaderLength else {
			return nil
		}

		return subdataWithRange(NSMakeRange(kNXTHeaderLength, length - kNXTHeaderLength))
	}
}
