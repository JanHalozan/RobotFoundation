//
//  EV3Response.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

import Foundation

public protocol EV3Response: MindstormsResponse {
	var length: UInt16 { get }
	var replyType: EV3ReplyType { get }
	var messageCounter: UInt16 { get }
}
