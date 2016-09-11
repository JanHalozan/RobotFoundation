//
//  LegacyUSBTransportService.h
//  LegacyUSBTransportService
//
//  Created by Matt on 6/29/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TransportServiceProtocol;

@protocol LegacyUSBTransportServiceDelegate
- (void)handleData:(NSData *)data;
@end


// LegacyUSBTransportService only works with Bulk In/Out transfers.
// It has also only been tested while talking to devices configured by the AppleUSBComposite driver.
@interface LegacyUSBTransportService : NSObject <TransportServiceProtocol>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id <LegacyUSBTransportServiceDelegate>)delegate;

@property (nonatomic, weak) id <LegacyUSBTransportServiceDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
