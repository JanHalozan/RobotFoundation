//
//  NXTCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol NXTCommand: MindstormsCommand, CustomDebugStringConvertible {
	var responseType: NXTResponse.Type { get }

	var identifier: UInt8 { get }
}

extension NXTCommand {
	var debugDescription: String {
		return "MRNXTCommand [type=\(type), identifier=\(identifier)]"
	}
}
