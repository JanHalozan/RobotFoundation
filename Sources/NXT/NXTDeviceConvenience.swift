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

// 64 bytes total is the max over Bluetooth, and there is a 6 byte header, so the max chunk is 58.
private let kMaxChunk = 58

public typealias NXTDeviceDownloadHandler = (NSData?) -> ()
public typealias NXTDeviceUploadHandler = (Bool) -> ()

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

	public func uploadFileData(wholeData: NSData, toPath path: String, handler: NXTDeviceUploadHandler) {
		let openCommand = NXTOpenWriteCommand(filename: path, size: UInt32(wholeData.length))
		enqueueCommand(openCommand) { response in
			guard let handleResponse = response as? NXTHandleResponse else {
				assertionFailure()
				return
			}

			if handleResponse.status == .StatusSuccess {
				self.actuallyUploadFileData(wholeData, toFileAtHandle: handleResponse.handle, handler: handler)
			} else {
				handler(false)
			}
		}
	}

	private func actuallyUploadFileData(wholeData: NSData, toFileAtHandle handle: UInt8, handler: NXTDeviceUploadHandler) {
		var anyFailed = false
		var dataLeft = wholeData

		while dataLeft.length > 0 {
			let chunk: NSData
			if dataLeft.length > kMaxChunk {
				chunk = dataLeft.subdataWithRange(NSMakeRange(0, kMaxChunk))
				dataLeft = dataLeft.subdataWithRange(NSMakeRange(kMaxChunk, dataLeft.length - kMaxChunk))
			} else {
				chunk = dataLeft
				dataLeft = NSData()
			}

			let command = NXTWriteCommand(handle: handle, contents: chunk)
			enqueueCommand(command) { response in
				guard let handleResponse = response as? NXTHandleSizeResponse else {
					assertionFailure()
					return
				}
				
				if handleResponse.status != .StatusSuccess {
					anyFailed = true
				}
			}
		}

		closeHandle(handle)

		enqueueBarrier {
			handler(!anyFailed)
		}
	}

	public func downloadFileAtPath(path: String, handler: NXTDeviceDownloadHandler) {
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

	private func continueFileDownloadWithHandle(handle: UInt8, bytesLeft: UInt16, dataSoFar: NSData, handler: EV3DeviceDownloadHandler) {
		let bytesToRead = bytesLeft > UInt16(kMaxChunk) ? UInt16(kMaxChunk) : UInt16(bytesLeft)
		let continueCommand = NXTReadCommand(handle: handle, bytesToRead: bytesToRead)
		enqueueCommand(continueCommand) { continueResponse in
			let dataResponse = continueResponse as! NXTDataResponse
			let newDataSoFar = dataSoFar.dataByAppendingData(dataResponse.contents)

			if dataResponse.status == .StatusSuccess {
				let newBytesLeft = bytesLeft - bytesToRead
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
