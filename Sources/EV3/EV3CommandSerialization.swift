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
private let packetLengthLength = sizeof(UInt16)

extension EV3DirectCommand {
	func formEV3PacketData(messageCounter: UInt16, prependTotalLength: Bool) -> NSData {
		let packet = NSMutableData()

		let dataLength = UInt16(payloadData.length + headerLength + typeLength + messageCounterLength)

		if prependTotalLength {
			let totalLength = dataLength + UInt16(packetLengthLength)
			packet.appendUInt16(totalLength)
		}

		packet.appendUInt16(dataLength)
		packet.appendUInt16(messageCounter)
		packet.appendUInt8(telegramType)
		packet.appendUInt16(globalSpaceSize)
		packet.appendData(payloadData)

		return packet
	}
}

extension EV3SystemCommand {
	func formEV3PacketData(messageCounter: UInt16) -> NSData {
		let dataLength = UInt16(payloadData.length + headerLength + typeLength + messageCounterLength)

		let packet = NSMutableData()
		packet.appendUInt16(dataLength)
		packet.appendUInt16(messageCounter)
		packet.appendUInt8(telegramType)
		packet.appendUInt8(systemCommand)
		packet.appendData(payloadData)

		return packet
	}
}
