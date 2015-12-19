//
//  NXTCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol NXTCommand: CustomDebugStringConvertible {
	var type: NXTCommandType { get }
	var identifier: UInt8 { get }
	var payloadData: NSData { get }
}

extension NXTCommand {
	var telegramType: UInt8 {
		if type == .Direct {
			return 0x0
		}

		return 0x01
	}
}

extension NXTCommand {
	var debugDescription: String {
		return "MRNXTCommand [type=\(type), identifier=\(identifier)]"
	}
}
