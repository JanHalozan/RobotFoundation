//
//  EV3CreateFolderCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3CreateFolderCommand: EV3SystemCommand {
	public let path: String

	public init(path: String) {
		self.path = path
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var systemCommand: UInt8 {
		return 0x9B
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendString(path)

		return mutableData.copy() as! NSData
	}
}
