//
//  HIDTransportService.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

#import "HIDTransportService.h"

@implementation HIDTransportService

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
