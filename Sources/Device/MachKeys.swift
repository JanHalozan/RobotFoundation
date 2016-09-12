//
//  MachKeys.swift
//  RobotFoundation
//
//  Created by Matt on 9/11/16.
//

import Foundation

enum MachRequestType: String {
	case openConnection = "openConnection"
	case writeData = "writeData"
}

enum MachResponseType: String {
	case receivedData = "receivedData"
	case receivedWriteResponse = "receivedWriteResponse"
	case closedConnection = "closedConnection"
}

enum MachEventKey: String {
	case type = "type"
	case data = "data"
	case identifier = "identifier"
	case result = "result"
	case counter = "counter"
}
