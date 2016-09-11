//
//  RBMachBootstrapServer.h
//  RobotFoundation
//
//  Created by Matt on 9/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBMachBootstrapServer : NSObject

+ (nullable NSMachPort *)portWithName:(NSString *)name;
+ (BOOL)registerPort:(NSMachPort *)port withName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
