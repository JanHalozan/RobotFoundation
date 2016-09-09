//
//  EV3CommandSerialization.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

private let headerLength = MemoryLayout<UInt16>.size
private let typeLength = MemoryLayout<UInt8>.size
private let messageCounterLength = MemoryLayout<UInt16>.size
private let commandLength = MemoryLayout<UInt8>.size
private let packetLengthLength = MemoryLayout<UInt16>.size

func formEV3PacketDataForCommands(_ commands: [EV3DirectCommand], messageCounter: UInt16) -> Data {
	if commands.isEmpty {
		return Data()
	}

	var totalPayloadLength = headerLength + typeLength + messageCounterLength
	var currentGlobalOffset = UInt16()
	var entirePayload = Data()

	for command in commands {
		let payload = command.payloadDataWithGlobalOffset(currentGlobalOffset)
		totalPayloadLength += payload.count
		currentGlobalOffset += command.globalSpaceSize
		entirePayload.append(payload)
	}

	var packet = Data()
	packet.appendUInt16(UInt16(totalPayloadLength))
	packet.appendUInt16(messageCounter)
	packet.appendUInt8(kDirectTelegramType)
	packet.appendUInt16(currentGlobalOffset)
	packet.append(entirePayload)

	return packet
}

extension EV3SystemCommand {
	func formEV3PacketData(_ messageCounter: UInt16) -> Data {
		let dataLength = UInt16(messageCounterLength + typeLength + commandLength + payloadData.count)

		var packet = Data()
		packet.appendUInt16(dataLength)
		packet.appendUInt16(messageCounter)
		packet.appendUInt8(kSystemTelegramType)
		packet.appendUInt8(systemCommand)
		packet.append(payloadData)

		return packet
	}
}
