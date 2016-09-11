//
//  XPCTransportServiceProtocol.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

#if os(OSX)

import Foundation

@objc protocol TransportClientProtocol {
	func handleTransportData(_ data: NSData)
	func closedTransportConnection()
}

@objc protocol TransportServiceProtocol {
	init(delegate: TransportClientProtocol)

	func writeData(_ data: NSData, identifier: NSString, handler: @escaping (Int) -> ())
	func scheduleRead(_ identifier: NSString, handler: @escaping (Int) -> ())
}

#endif
