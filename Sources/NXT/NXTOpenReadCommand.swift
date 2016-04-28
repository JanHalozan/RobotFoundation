//
//  NXTOpenReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTOpenReadCommand: NXTCommand {
	public let filename: String

	public init(filename: String) {
		self.filename = filename
	}

	public var responseType: MindstormsResponse.Type {
		return NXTHandleSizeResponse.self
	}

	public var type: MindstormsCommandType {
		return .System
	}

	public var identifier: UInt8 {
		return 0x80
	}

	public var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
