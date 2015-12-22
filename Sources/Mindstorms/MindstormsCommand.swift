//
//  MindstormsCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public protocol MindstormsCommand {
	var responseType: MindstormsResponse.Type { get }
	var type: MindstormsCommandType { get }
	var payloadData: NSData { get }
}

extension MindstormsCommand {
	// TODO: support no-reply variants
	var telegramType: UInt8 {
		if type == .Direct {
			return 0x0
		}

		return 0x01
	}
}
