//
//  EV3PlaySoundFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/30/16.
//

import Foundation

public struct EV3PlaySoundFileCommand: EV3DirectCommand {
	public let path: String
	public let volume: UInt8

	public init?(path: String, volume: UInt8) {
		// Paths to sound files must not have the RSF extension. If it's there, remove it. If there's any other extension, fail.
		let cocoaPath = path as NSString
		if cocoaPath.pathExtension.isEmpty {
			self.path = path
		}
		else {
			if cocoaPath.pathExtension.lowercaseString == "rsf" {
				self.path = cocoaPath.stringByDeletingPathExtension
			}
			else {
				return nil
			}
		}

		self.volume = volume
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.Sound.rawValue)
		mutableData.appendUInt8(EV3SoundOpSubcode.Play.rawValue)
		mutableData.appendLC1(volume)
		mutableData.appendLCS(path)

		return mutableData.copy() as! NSData
	}
}
