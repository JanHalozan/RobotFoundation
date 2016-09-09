//
//  NXTGetDeviceInfoCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTGetDeviceInfoCommand: NXTCommand {
	public init() {}

	public var responseType: MindstormsResponse.Type {
		return NXTDeviceInfoResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x9B
	}

	public var payloadData: Data {
		return Data()
	}
}
