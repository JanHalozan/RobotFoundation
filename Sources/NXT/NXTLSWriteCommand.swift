//
//  NXTLSWriteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 9/7/16.
//

import Foundation

public struct NXTLSWriteCommand: NXTCommand {
	public let port: NXTInputPort
	public let txData: Data
	public let rxDataLength: UInt8

	public init(port: NXTInputPort, txData: Data, rxDataLength: UInt8) {
		self.port = port
		self.txData = txData
		self.rxDataLength = rxDataLength
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .direct
	}

	public var identifier: UInt8 {
		return 0x0F
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(port.rawValue)
		data.appendUInt8(UInt8(txData.count))
		data.appendUInt8(rxDataLength)
		data.append(txData)
		return data
	}
}
