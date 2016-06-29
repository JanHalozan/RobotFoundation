//
//  LegacyUSBTransportService.h
//  LegacyUSBTransportService
//
//  Created by Matt on 6/29/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XPCTransportServiceProtocol;

@protocol LegacyUSBTransportServiceDelegate
- (void)handleData:(NSData *)data;
@end


@interface LegacyUSBTransportService : NSObject <XPCTransportServiceProtocol>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id <LegacyUSBTransportServiceDelegate>)delegate;

@property (nonatomic, weak) id <LegacyUSBTransportServiceDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
