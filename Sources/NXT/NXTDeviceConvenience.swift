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

public typealias NXTDeviceDownloadHandler = (Data?) -> ()
public typealias NXTDeviceUploadHandler = (Bool) -> ()

// Offers convenience API for "sequential" commands.
extension NXTDevice {
	public func readDisplay(_ handler: @escaping (Data?) -> ()) {
		let allData = NSMutableData()
		var allGood = true

		for n: UInt16 in 0..<16 {
			let command = NXTReadIOMapCommand(module: kDisplayModule, offset: kDisplayNormalOffset + (n * kMaxBytes), bytesToRead: kMaxBytes)
			enqueueCommand(command, isCritical: false) { result in
				assert(Thread.isMainThread)

				switch result {
				case .error:
					allGood = false
				case .response(let response):
					guard let nxtResponse = response as? NXTIOMapResponse else {
						allGood = false
						assertionFailure()
						break
					}

					allData.append(nxtResponse.contents)
				}
			}
		}

		enqueueBarrier {
			if allGood {
				handler(allData as Data)
			} else {
				handler(nil)
			}
		}
	}

	public func uploadFileData(_ wholeData: Data, toPath path: String, handler: @escaping NXTDeviceUploadHandler) {
		let openCommand = NXTOpenWriteCommand(filename: path, size: UInt32(wholeData.count))
		enqueueCommand(openCommand) { result in
			assert(Thread.isMainThread)

			switch result {
			case .error:
				handler(false)
			case .response(let response):
				guard let handleResponse = response as? NXTHandleResponse else {
					handler(false)
					assertionFailure()
					return
				}

				self.actuallyUploadFileData(wholeData, toFileAtHandle: handleResponse.handle, handler: handler)
			}
		}
	}

	private func actuallyUploadFileData(_ wholeData: Data, toFileAtHandle handle: UInt8, handler: @escaping NXTDeviceUploadHandler) {
		var allGood = true
		var dataLeft = wholeData

		while dataLeft.count > 0 {
			let chunk: Data
			if dataLeft.count > kMaxChunk {
				chunk = dataLeft.subdata(in: 0..<kMaxChunk)
				dataLeft = dataLeft.subdata(in: kMaxChunk..<dataLeft.count)
			} else {
				chunk = dataLeft
				dataLeft = Data()
			}

			let command = NXTWriteCommand(handle: handle, contents: chunk)
			enqueueCommand(command) { result in
				assert(Thread.isMainThread)

				switch result {
				case .error:
					allGood = false
				case .response(let response):
					guard let _ = response as? NXTHandleSizeResponse else {
						allGood = false
						assertionFailure()
						break
					}
				}
			}
		}

		closeHandle(handle)

		enqueueBarrier {
			handler(allGood)
		}
	}

	public func downloadFileAtPath(_ path: String, handler: @escaping NXTDeviceDownloadHandler) {
		let command = NXTOpenReadCommand(filename: path)
		enqueueCommand(command) { result in
			assert(Thread.isMainThread)

			switch result {
			case .error:
				handler(nil)
			case .response(let response):
				guard let openResponse = response as? NXTHandleSizeResponse else {
					handler(nil)
					assertionFailure()
					break
				}

				// We finished reading but there is more!
				self.continueFileDownloadWithHandle(openResponse.handle, bytesLeft: openResponse.size, dataSoFar: Data(), handler: handler)
			}
		}
	}

	private func continueFileDownloadWithHandle(_ handle: UInt8, bytesLeft: UInt16, dataSoFar: Data, handler: @escaping EV3DeviceDownloadHandler) {
		let bytesToRead = bytesLeft > UInt16(kMaxChunk) ? UInt16(kMaxChunk) : UInt16(bytesLeft)
		let continueCommand = NXTReadCommand(handle: handle, bytesToRead: bytesToRead)
		enqueueCommand(continueCommand) { result in
			assert(Thread.isMainThread)

			switch result {
			case .error:
				handler(nil)
			case .response(let response):
				guard let dataResponse = response as? NXTDataResponse else {
					handler(nil)
					assertionFailure()
					break
				}

				let newDataSoFar = dataSoFar.dataByAppendingData(dataResponse.contents)

				let newBytesLeft = bytesLeft - bytesToRead
				if newBytesLeft == 0 {
					handler(newDataSoFar)
					self.closeHandle(handle)
				} else {
					// We finished reading but there is more!
					self.continueFileDownloadWithHandle(handle, bytesLeft: newBytesLeft, dataSoFar: newDataSoFar, handler: handler)
				}
			}
		}
	}

	private func closeHandle(_ handle: UInt8) {
		let closeCommand = NXTCloseCommand(handle: handle)
		enqueueCommand(closeCommand) { result in
			assert(Thread.isMainThread)

			switch result {
			case .error:
				// If it failed there's nothing we can do.
				break
			case .response(let response):
				guard let genericResponse = response as? NXTGenericResponse else {
					assertionFailure()
					break
				}

				print("Closing the file handle failed (\(genericResponse.status))")
			}
		}
	}
}
