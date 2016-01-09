//
//  EV3DeviceConvenience.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

import Foundation

public typealias EV3DeviceDownloadHandler = NSData -> ()
public typealias EV3DeviceUploadHandler = Bool -> ()

// Offers convenience API for "sequential" commands.
extension EV3Device {
	public func uploadFileData(var dataLeft: NSData, toPath path: String, handler: EV3DeviceUploadHandler) {
		var first = true

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
			enqueueCommand(command) { response in
				let handleResponse = response as! EV3GenericResponse
				//TODO: handle responses
			}
		}
	}

	public func downloadFileAtPath(path: String, handler: EV3DeviceDownloadHandler) {
		let command = EV3ReadFileCommand(path: path, bytesToRead: 1000)
		enqueueCommand(command) { response in
			let listingResponse = response as! EV3FileResponse

			if listingResponse.returnStatus == .EndOfFile {
				handler(listingResponse.data)
			} else if listingResponse.returnStatus == .Success {
				// We finished reading but there is more!
				self.continueFileDownloadWithHandle(listingResponse.handle, dataSoFar: listingResponse.data, handler: handler)
			} else {
				assertionFailure()
			}
		}
	}

	private func continueFileDownloadWithHandle(handle: UInt8, dataSoFar: NSData, handler: EV3DeviceDownloadHandler) {
		let continueCommand = EV3ContinueReadFileCommand(handle: handle, bytesToRead: 1000)
		enqueueCommand(continueCommand) { continueResponse in
			let listingResponse = continueResponse as! EV3ContinueFileResponse
			let newDataSoFar = dataSoFar.dataByAppendingData(listingResponse.data)

			if listingResponse.returnStatus == .EndOfFile {
				handler(newDataSoFar)
			} else if listingResponse.returnStatus == .Success {
				// We finished reading but there is more!
				self.continueFileDownloadWithHandle(listingResponse.handle, dataSoFar: newDataSoFar, handler: handler)
			} else {
				assertionFailure()
			}
		}
	}
}
