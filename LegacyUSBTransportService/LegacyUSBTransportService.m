//
//  LegacyUSBTransportService.m
//  LegacyUSBTransportService
//
//  Created by Matt on 6/29/16.
//

#import "LegacyUSBTransportService.h"

#import "LegacyUSBTransportService-Swift.h"

@implementation LegacyUSBTransportService

- (instancetype)initWithDelegate:(id<LegacyUSBTransportServiceDelegate>)delegate
{
	if (!(self = [super init])) {
		return nil;
	}

	_delegate = delegate;

	return self;
}

- (void)open:(NSString *)identifier handler:(void (^)(NSInteger))handler
{

}

- (void)close:(NSString *)identifier handler:(void (^)(NSInteger))handler
{

}

- (void)writeData:(NSString *)identifier data:(NSData *)data handler:(void (^)(NSInteger))handler
{

}

@end
