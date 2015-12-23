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
	func formEV3PacketData(var messageCounter: UInt16, prependTotalLength: Bool) -> NSData {
		let byteCodeData = payloadData

		let packet = NSMutableData()

		var dataLength = byteCodeData.length + headerLength + typeLength + messageCounterLength
		var totalLength = dataLength + packetLengthLength

		if prependTotalLength {
			packet.appendBytes(&totalLength, length: sizeof(UInt16))
		}

		var type = self.telegramType

		packet.appendBytes(&dataLength, length: sizeof(UInt16))
		packet.appendBytes(&messageCounter, length: sizeof(UInt16))
		packet.appendBytes(&type, length: sizeof(UInt8))
		packet.appendUInt8(numberOfGlobals)
		packet.appendUInt8(0)
		packet.appendData(byteCodeData)

		return packet
	}
}
