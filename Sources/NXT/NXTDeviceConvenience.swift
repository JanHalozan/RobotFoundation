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

public typealias NXTDeviceDownloadHandler = NSData -> ()
public typealias NXTDeviceUploadHandler = Bool -> ()

// Offers convenience API for "sequential" commands.
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

	public func downloadFileAtPath(path: String, handler: NXTDeviceDownloadHandler) {
		// 64 is the max over Bluetooth.
		let command = NXTOpenReadCommand(filename: path)
		enqueueCommand(command) { response in
			let openResponse = response as! NXTHandleSizeResponse

			if openResponse.status == .StatusSuccess {
				// We finished reading but there is more!
				self.continueFileDownloadWithHandle(openResponse.handle, bytesLeft: openResponse.size, dataSoFar: NSData(), handler: handler)
			} else {
				assertionFailure()
			}
		}
	}

	private func continueFileDownloadWithHandle(handle: UInt8, bytesLeft: UInt32, dataSoFar: NSData, handler: EV3DeviceDownloadHandler) {
		let bytesToRead = bytesLeft > 64 ? UInt16(64) : UInt16(bytesLeft)
		let continueCommand = NXTReadCommand(handle: handle, bytesToRead: bytesToRead)
		enqueueCommand(continueCommand) { continueResponse in
			let dataResponse = continueResponse as! NXTDataResponse
			let newDataSoFar = dataSoFar.dataByAppendingData(dataResponse.contents)

			if dataResponse.status == .StatusSuccess {
				let newBytesLeft = bytesLeft - UInt32(bytesToRead)
				if newBytesLeft == 0 {
					handler(newDataSoFar)
					self.closeHandle(handle)
				} else {
					// We finished reading but there is more!
					self.continueFileDownloadWithHandle(handle, bytesLeft: newBytesLeft, dataSoFar: newDataSoFar, handler: handler)
				}
			} else {
				assertionFailure()
			}
		}
	}

	private func closeHandle(handle: UInt8) {
		let closeCommand = NXTCloseCommand(handle: handle)
		enqueueCommand(closeCommand) { response in
			guard let genericResponse = response as? NXTGenericResponse else {
				assertionFailure()
				return
			}

			if genericResponse.status != .StatusSuccess {
				debugPrint("Closing the file handle failed (\(genericResponse.status))")
			}
		}
	}
}
