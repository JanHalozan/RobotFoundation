//
//  NXTCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public protocol NXTCommand: MindstormsCommand, CustomDebugStringConvertible {
	var identifier: UInt8 { get }
}

extension NXTCommand {
	public var debugDescription: String {
		return "MRNXTCommand [type=\(type), identifier=\(identifier)]"
	}
}
