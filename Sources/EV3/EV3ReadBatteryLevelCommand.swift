//
//  EV3ReadBatteryLevelCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct EV3ReadBatteryLevelCommand: EV3Command {
	var responseType: MindstormsResponse.Type {
		return EV3BatteryLevelResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		// UI read op code
		mutableData.appendUInt8(0x81)

		// Get battery level command (reads a value between 0 - 100%).
		mutableData.appendUInt8(18)

		return mutableData.copy() as! NSData
	}
}

struct EV3BatteryLevelResponse: MindstormsResponse {
	let replyType: EV3ReplyType
	let messageCounter: UInt16

	let batteryLevel: UInt8

	init?(data: NSData) {
		guard let (messageCounter, replyType) = processGenericResponseForData(data) else {
			return nil
		}

		self.replyType = replyType
		self.messageCounter = messageCounter
		self.batteryLevel = data.readUInt8AtIndex(5)
	}
}
