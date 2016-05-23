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

	var totalPayloadLength = headerLength + typeLength + messageCounterLength
	var totalGlobalSpace = UInt16()
	var currentGlobalOffset = EV3Variables.GlobalVar0.rawValue
	let entirePayload = NSMutableData()

	for command in commands {
		let payload = command.payloadDataWithGlobalOffset(currentGlobalOffset)
		totalPayloadLength += payload.length
		totalGlobalSpace += command.globalSpaceSize
		currentGlobalOffset += UInt8(command.globalSpaceSize)
		entirePayload.appendData(payload)
	}

	let packet = NSMutableData()
	packet.appendUInt16(UInt16(totalPayloadLength))
	packet.appendUInt16(messageCounter)
	packet.appendUInt8(kDirectTelegramType)
	packet.appendUInt16(totalGlobalSpace)
	packet.appendData(entirePayload)

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
