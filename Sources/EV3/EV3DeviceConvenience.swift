//
//  EV3DeviceConvenience.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

import Foundation

public typealias EV3DeviceDownloadHandler = (Data?) -> ()
public typealias EV3DeviceUploadHandler = (Bool) -> ()

private let kDownloadChunkSize = 768

// Offers convenience API for "sequential" commands.
extension EV3Device {
	public func uploadFileData(_ wholeData: Data, toPath path: String, handler: @escaping EV3DeviceUploadHandler) {
		var first = true
		var anyFailed = false
		var dataLeft = wholeData

		while dataLeft.count > 0 {
			let chunk: Data
			let type: EV3WriteChainedType

			if first {
				type = .write
				first = false
			} else {
				type = .append
			}

			let kMaxChunk = 64
			if dataLeft.count > kMaxChunk {
				chunk = dataLeft.subdata(in: 0..<kMaxChunk)
				dataLeft = dataLeft.subdata(in: kMaxChunk..<dataLeft.count)
			} else {
				chunk = dataLeft
				dataLeft = Data()
			}

			let command = EV3WriteChainedCommand(path: path, data: chunk, type: type)
			enqueueCommand(command) { result in
				assert(Thread.isMainThread)
				switch result {
				case .error:
					anyFailed = true
				case .responseGroup:
					break
				}
			}
		}

		enqueueBarrier {
			handler(!anyFailed)
		}
	}

	public func downloadFileAtPath(_ path: String, handler: @escaping EV3DeviceDownloadHandler) {
		// Try to read more than we might have. We'll sort it out later.
		let command = EV3ReadFileCommand(path: path, bytesToRead: UInt16(kDownloadChunkSize))
		enqueueCommand(command) { result in
			switch result {
			case .error:
				handler(nil)
			case .responseGroup(let responseGroup):
				guard let listingResponse = responseGroup.firstResponse as? EV3FileResponse else {
					handler(nil)
					assertionFailure()
					return
				}

				let fileSize = Int(listingResponse.fileSize)

				if listingResponse.returnStatus == .endOfFile {
					assert(fileSize <= kDownloadChunkSize)
					handler(listingResponse.data.subdata(in: 0..<fileSize))
				} else if listingResponse.returnStatus == .success {
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

	private func continueFileDownloadWithHandle(_ handle: UInt8, dataSoFar: Data, bytesLeft: Int, handler: @escaping EV3DeviceDownloadHandler) {
		let bytesToReadNow = min(bytesLeft, kDownloadChunkSize)
		let continueCommand = EV3ContinueReadFileCommand(handle: handle, bytesToRead: UInt16(bytesToReadNow))
		enqueueCommand(continueCommand) { result in
			switch result {
			case .error:
				handler(nil)
			case .responseGroup(let responseGroup):
				guard let listingResponse = responseGroup.firstResponse as? EV3ContinueFileResponse else {
					handler(nil)
					assertionFailure()
					return
				}

				if listingResponse.returnStatus == .endOfFile {
					assert(listingResponse.data.count == bytesToReadNow)
					let newDataSoFar = dataSoFar.dataByAppendingData(listingResponse.data)
					handler(newDataSoFar)
				} else if listingResponse.returnStatus == .success {
					// We finished reading but there is more!
					assert(listingResponse.data.count == bytesToReadNow)
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
