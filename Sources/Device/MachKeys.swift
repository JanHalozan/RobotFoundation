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
	case scheduleRead = "scheduleRead"
}

enum MachResponseType: String {
	case receivedData = "receivedData"
	case closedConnection = "closedConnection"
}

enum MachEventKey: String {
	case type = "type"
	case data = "data"
	case identifier = "identifier"
}
