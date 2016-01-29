//
//  NXTGetDeviceInfoCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTGetDeviceInfoCommand: NXTCommand {
	let filename: String

	var responseType: MindstormsResponse.Type {
		return NXTDeviceInfoResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x9B
	}

	var payloadData: NSData {
		return NSData()
	}
}
