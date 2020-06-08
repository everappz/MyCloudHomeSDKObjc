//
//  MCHDevice.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHDevice.h"

@implementation MCHDevice

- (NSString *)name{
    return [self.class stringForKey:@"name" inDictionary:self.dictionary];
}

- (NSString *)deviceId{
    return [self.class stringForKey:@"deviceId" inDictionary:self.dictionary];
}

- (NSDictionary *)network{
    return [self.class dictionaryForKey:@"network" inDictionary:self.dictionary];
}

- (NSURL *)localIpAddress{
    return [self.class HTTPURLForKey:@"localIpAddress" inDictionary:self.network];
}

- (NSURL *)externalIpAddress{
    return [self.class HTTPURLForKey:@"externalIpAddress" inDictionary:self.network];
}

- (NSString *)internalDNSName{
    return [self.class stringForKey:@"internalDNSName" inDictionary:self.network];
}

- (NSString *)tunnelId{
    return [self.class stringForKey:@"tunnelId" inDictionary:self.network];
}

- (NSURL *)internalURL{
    return [self.class HTTPURLForKey:@"internalURL" inDictionary:self.network];
}

- (NSURL *)proxyURL{
    return [self.class HTTPURLForKey:@"proxyURL" inDictionary:self.network];
}

@end
