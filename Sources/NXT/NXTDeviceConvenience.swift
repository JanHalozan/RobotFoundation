//
//  NXTDeviceConvenience.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

private let kDisplayModule: UInt32 = 0x000A0001
private let kDisplayNormalOffset: UInt16 = 119
private let kMaxBytes: UInt16 = 50

extension NXTDevice {
	public func readDisplay(handler: NSData -> ()) {
		let allData = NSMutableData()

		for n: UInt16 in 0..<16 {
			let command = NXTReadIOMapCommand(module: kDisplayModule, offset: kDisplayNormalOffset + (n * kMaxBytes), bytesToRead: kMaxBytes)
			enqueueCommand(command) { response in
				guard let nxtResponse = response as? NXTIOMapResponse else {
					assertionFailure()
					return
				}

				allData.appendData(nxtResponse.contents)

				if allData.length == kNXTScreenHeight/8 * kNXTScreenWidth {
					handler(allData)
				}
			}
		}
	}
}
