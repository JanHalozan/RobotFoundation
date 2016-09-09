//
//  NXTPlaySoundFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTPlaySoundFileCommand: NXTCommand {
	public let loop: Bool
	public let filename: String

	public init(filename: String, loop: Bool) {
		self.filename = filename
		self.loop = loop
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .direct
	}

	public var identifier: UInt8 {
		return 0x02
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(loop ? 1 : 0)
		data.appendNXTFilename(filename)
		return data
	}
}
