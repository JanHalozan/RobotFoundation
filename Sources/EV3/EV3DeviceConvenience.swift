//
//  EV3DeviceConvenience.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

import Foundation

public typealias EV3DeviceDownloadHandler = (NSData?) -> ()
public typealias EV3DeviceUploadHandler = (Bool) -> ()

private let kDownloadChunkSize = 768

// Offers convenience API for "sequential" commands.
extension EV3Device {
	public func uploadFileData(wholeData: NSData, toPath path: String, handler: EV3DeviceUploadHandler) {
		var first = true
		var anyFailed = false
		var dataLeft = wholeData

		while dataLeft.length > 0 {
			let chunk: NSData
			let type: EV3WriteChainedType

			if first {
				type = .Write
				first = false
			} else {
				type = .Append
			}

			let kMaxChunk = 64
			if dataLeft.length > kMaxChunk {
				chunk = dataLeft.subdataWithRange(NSMakeRange(0, kMaxChunk))
				dataLeft = dataLeft.subdataWithRange(NSMakeRange(kMaxChunk, dataLeft.length - kMaxChunk))
			} else {
				chunk = dataLeft
				dataLeft = NSData()
			}

			let command = EV3WriteChainedCommand(path: path, data: chunk, type: type)
			enqueueCommand(command) { result in
				assert(NSThread.isMainThread())
				switch result {
				case .Error:
					anyFailed = true
				case .ResponseGroup:
					break
				}
			}
		}

		enqueueBarrier {
			handler(!anyFailed)
		}
	}

	public func downloadFileAtPath(path: String, handler: EV3DeviceDownloadHandler) {
		// Try to read more than we might have. We'll sort it out later.
		let command = EV3ReadFileCommand(path: path, bytesToRead: UInt16(kDownloadChunkSize))
		enqueueCommand(command) { result in
			switch result {
			case .Error:
				handler(nil)
			case .ResponseGroup(let responseGroup):
				guard let listingResponse = responseGroup.firstResponse as? EV3FileResponse else {
					handler(nil)
					assertionFailure()
					return
				}

				let fileSize = Int(listingResponse.fileSize)

				if listingResponse.returnStatus == .EndOfFile {
					assert(fileSize <= kDownloadChunkSize)
					handler(listingResponse.data.subdataWithRange(NSMakeRange(0, fileSize)))
				} else if listingResponse.returnStatus == .Success {
					// We finished reading but there is more!
					assert(fileSize > kDownloadChunkSize)
					self.continueFileDownloadWithHandle(listingResponse.handle, dataSoFar: listingResponse.data, bytesLeft: fileSize - kDownloadChunkSize, handler: handler)
				} else {
					handler(nil)
					assertionFailure()
				}
			}
		}
	}

	private func continueFileDownloadWithHandle(handle: UInt8, dataSoFar: NSData, bytesLeft: Int, handler: EV3DeviceDownloadHandler) {
		let bytesToReadNow = min(bytesLeft, kDownloadChunkSize)
		let continueCommand = EV3ContinueReadFileCommand(handle: handle, bytesToRead: UInt16(bytesToReadNow))
		enqueueCommand(continueCommand) { result in
			switch result {
			case .Error:
				handler(nil)
			case .ResponseGroup(let responseGroup):
				guard let listingResponse = responseGroup.firstResponse as? EV3ContinueFileResponse else {
					handler(nil)
					assertionFailure()
					return
				}

				if listingResponse.returnStatus == .EndOfFile {
					assert(listingResponse.data.length == bytesToReadNow)
					let newDataSoFar = dataSoFar.dataByAppendingData(listingResponse.data)
					handler(newDataSoFar)
				} else if listingResponse.returnStatus == .Success {
					// We finished reading but there is more!
					assert(listingResponse.data.length == bytesToReadNow)
					let newDataSoFar = dataSoFar.dataByAppendingData(listingResponse.data)
					self.continueFileDownloadWithHandle(listingResponse.handle, dataSoFar: newDataSoFar, bytesLeft: bytesLeft - bytesToReadNow, handler: handler)
				} else {
					handler(nil)
					assertionFailure()
				}
			}
		}
	}
}
