//
//  NXTDeleteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct NXTDeleteCommand: NXTCommand {
	public let filename: String

	public init(filename: String) {
		self.filename = filename
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .system
	}

	public var identifier: UInt8 {
		return 0x85
	}

	public var payloadData: Data {
		return filename.dataForFilename
	}
}
