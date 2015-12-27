//
//  XPCTransportServiceProtocol.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

#if os(OSX)

import Foundation

@objc protocol XPCTransportServiceProtocol {
	func open(identifier: NSString, handler: Int -> ())
	func writeData(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ())
	func close(identifier: NSString, handler: Int -> ())
}

#endif
