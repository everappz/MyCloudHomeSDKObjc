//
//  MCHDevice.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCHDevice : MCHObject

- (NSString * _Nullable)name;

- (NSString * _Nullable)deviceId;

- (NSDictionary * _Nullable)network;

- (NSURL * _Nullable)localIpAddress;

- (NSURL * _Nullable)externalIpAddress;

- (NSString * _Nullable)internalDNSName;

- (NSString * _Nullable)tunnelId;

- (NSURL * _Nullable)internalURL;

- (NSURL * _Nullable)proxyURL;

@end

NS_ASSUME_NONNULL_END
