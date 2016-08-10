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

func processReplyWithResponseData(data: NSData) -> (UInt8, NXTStatus)? {
	guard data.length >= kNXTHeaderLength else {
		return nil
	}

	let headerData = data.subdataWithRange(NSMakeRange(0, kNXTHeaderLength))

	let code = headerData.readUInt8AtIndex(0)

	// All replies start with 0x2
	guard code == 0x2 else {
		return nil
	}

	let command = headerData.readUInt8AtIndex(1)
	let rawStatus = headerData.readUInt8AtIndex(2)
	let status = NXTStatus(rawValue: rawStatus) ?? .UndefinedError
	return (command, status)
}

extension NSData {
	var payloadData: NSData? {
		guard length >= kNXTHeaderLength else {
			return nil
		}

		return subdataWithRange(NSMakeRange(kNXTHeaderLength, length - kNXTHeaderLength))
	}
}
