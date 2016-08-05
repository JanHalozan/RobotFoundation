//
//  XPCTransportServiceProtocol.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

#if os(OSX)

import Foundation

@objc protocol XPCTransportClientProtocol {
	func handleTransportData(data: NSData)
}

@objc protocol XPCTransportServiceProtocol {
	func open(identifier: NSString, handler: Int -> ())
	func writeData(data: NSData, identifier: NSString, handler: Int -> ())
	func close(identifier: NSString, handler: Int -> ())

	func scheduleRead(identifier: NSString, handler: Int -> ())
}

#endif
