//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

import Foundation

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class HIDTransportService : NSObject, HIDTransportServiceProtocol {
	// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
	func upperCaseString(string: NSString, withReply reply: NSString -> ()) {
		let response = string.uppercaseString
		reply(response)
	}
}
