//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HIDTransportServiceProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface HIDTransportService : NSObject <HIDTransportServiceProtocol>
@end
