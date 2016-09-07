//
//  NXTLSWriteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 9/7/16.
//

import Foundation

public struct NXTLSWriteCommand: NXTCommand {
	public let port: NXTInputPort
	public let txData: NSData
	public let rxDataLength: UInt8

	public init(port: NXTInputPort, txData: NSData, rxDataLength: UInt8) {
		self.port = port
		self.txData = txData
		self.rxDataLength = rxDataLength
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x0F
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		data.appendUInt8(UInt8(txData.length))
		data.appendUInt8(rxDataLength)
		data.appendData(txData)
		return data.copy() as! NSData
	}
}
