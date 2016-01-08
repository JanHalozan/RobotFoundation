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
	public func uploadFileData(data: NSData, toPath path: String, handler: EV3DeviceUploadHandler) {
		let command = EV3UploadFileCommand(path: path, bytesToWrite: UInt32(data.length))
		enqueueCommand(command) { response in
			let handleResponse = response as! EV3HandleResponse

			self.continueFileUploadWithHandler(handleResponse.handle, dataLeft: data, handler: handler)
		}
	}

	private func continueFileUploadWithHandler(handle: UInt8, dataLeft: NSData, handler: EV3DeviceUploadHandler) {
		let chunk = dataLeft.length > 1000 ? dataLeft.subdataWithRange(NSMakeRange(0, 1000)) : dataLeft
		let moreToUpload = dataLeft.length > 1000

		let command = EV3ContinueUploadFileCommand(handle: handle, data: chunk)
		enqueueCommand(command) { response in

			if moreToUpload {
				let dataLeft = dataLeft.subdataWithRange(NSMakeRange(1000, dataLeft.length - 1000))
				self.continueFileUploadWithHandler(handle, dataLeft: dataLeft, handler: handler)
			} else {
				handler(true)
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
