//
//  EV3Command.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol EV3Command: MindstormsCommand {
	var numberOfGlobals: UInt8 { get }
}

extension EV3Command {
	var numberOfGlobals: UInt8 {
		return 0
	}
}
