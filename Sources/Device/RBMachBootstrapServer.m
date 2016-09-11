//
//  RBMachBootstrapServer.m
//  RobotFoundation
//
//  Created by Matt on 9/11/16.
//

#import "RBMachBootstrapServer.h"

@implementation RBMachBootstrapServer

+ (NSMachPort *)portWithName:(NSString *)name {
	NSPort *__nullable port = [[NSMachBootstrapServer sharedInstance] portForName:name];
	if ([port isKindOfClass:[NSMachPort class]]) {
		return (NSMachPort *)port;
	}

	return nil;
}

+ (BOOL)registerPort:(NSMachPort *)port withName:(NSString *)name {
	return [[NSMachBootstrapServer sharedInstance] registerPort:port name:name];
}

@end
