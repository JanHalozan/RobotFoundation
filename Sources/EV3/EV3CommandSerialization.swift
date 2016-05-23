//
//  EV3CommandSerialization.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

private let headerLength = sizeof(UInt16)
private let typeLength = sizeof(UInt8)
private let messageCounterLength = sizeof(UInt16)
private let commandLength = sizeof(UInt8)
private let packetLengthLength = sizeof(UInt16)

func formEV3PacketDataForCommands(commands: [EV3DirectCommand], messageCounter: UInt16) -> NSData {
	if commands.isEmpty {
		return NSData()
	}

	let totalPayloadLength = commands.reduce(0) { current, command in
		current + command.payloadData.length + headerLength + typeLength + messageCounterLength
	}

	let totalGlobalSpaceSize = commands.reduce(0) { current, command in
		current + command.globalSpaceSize
	}

	let entirePayloadData = commands.reduce(NSMutableData()) { current, command in
		current.appendData(command.payloadData)
		return current
	}

	let packet = NSMutableData()
	packet.appendUInt16(UInt16(totalPayloadLength))
	packet.appendUInt16(messageCounter)
	packet.appendUInt8(kDirectTelegramType)
	packet.appendUInt16(totalGlobalSpaceSize)
	packet.appendData(entirePayloadData)

	return packet
}

extension EV3SystemCommand {
	func formEV3PacketData(messageCounter: UInt16) -> NSData {
		let dataLength = UInt16(messageCounterLength + typeLength + commandLength + payloadData.length)

		let packet = NSMutableData()
		packet.appendUInt16(dataLength)
		packet.appendUInt16(messageCounter)
		packet.appendUInt8(kSystemTelegramType)
		packet.appendUInt8(systemCommand)
		packet.appendData(payloadData)

		return packet
	}
}
