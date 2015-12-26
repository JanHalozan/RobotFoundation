//
//  EV3DeviceConvenience.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

import Foundation

public typealias EV3DeviceDownloadHandler = NSData -> ()

// Offers convenience API for "sequential" commands.
extension EV3Device {
	public func downloadFileAtPath(path: String, handler: EV3DeviceDownloadHandler) {
		let command = EV3ReadFileCommand(path: path, bytesToRead: 1000)
		enqueueCommand(command) { response in
			let listingResponse = response as! EV3FileResponse
			let bytesLeft = listingResponse.fileSize > 1000 ? listingResponse.fileSize - 1000 : listingResponse.fileSize

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
		let continueCommand = EV3ContinueReadFileCommand(handle: handle)
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
