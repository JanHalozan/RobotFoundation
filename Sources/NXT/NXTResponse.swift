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

func processReplyWithResponseData(_ data: Data) -> (UInt8, NXTStatus)? {
	guard data.count >= kNXTHeaderLength else {
		return nil
	}

	let headerData = data.subdata(in: 0..<kNXTHeaderLength)

	let code = headerData.readUInt8AtIndex(0)

	// All replies start with 0x2
	guard code == 0x2 else {
		return nil
	}

	let command = headerData.readUInt8AtIndex(1)
	let rawStatus = headerData.readUInt8AtIndex(2)
	let status = NXTStatus(rawValue: rawStatus) ?? .undefinedError
	return (command, status)
}

extension Data {
	var payloadData: Data? {
		guard count >= kNXTHeaderLength else {
			return nil
		}

		return subdata(in: kNXTHeaderLength..<count)
	}
}
