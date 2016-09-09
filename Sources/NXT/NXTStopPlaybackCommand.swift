//
//  NXTStopPlaybackCommand.swift
//  RobotFoundation
//
//  Created by Matt on 4/1/16.
//

import Foundation

public struct NXTStopPlaybackCommand: NXTCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .direct
	}

	public var identifier: UInt8 {
		return 0x0C
	}

	public var payloadData: Data {
		return Data()
	}
}
