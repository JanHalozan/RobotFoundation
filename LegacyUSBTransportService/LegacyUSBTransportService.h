//
//  LegacyUSBTransportService.h
//  LegacyUSBTransportService
//
//  Created by Matt on 6/29/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TransportServiceProtocol;
@protocol TransportClientProtocol;

// LegacyUSBTransportService only works with Bulk In/Out transfers.
// It has also only been tested while talking to devices configured by the AppleUSBComposite driver.
@interface LegacyUSBTransportService : NSObject <TransportServiceProtocol>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id <TransportClientProtocol>)delegate;

@property (nonatomic, weak) id <TransportClientProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
