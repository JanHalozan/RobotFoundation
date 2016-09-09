//
//  NXTGetVersionCommand.swift
//  RobotFoundation
//
//  Created by Matt on 3/23/16.
//

import Foundation

public struct NXTGetVersionCommand: NXTCommand {
	public init() {}

	public var responseType: MindstormsResponse.Type {
		return NXTVersionResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x88
	}

	public var payloadData: Data {
		return Data()
	}
}
