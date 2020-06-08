//
//  MCHEndpointConfiguration.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//


#import "MCHEndpointConfiguration.h"
#import "MCHConstants.h"

@implementation MCHEndpointConfiguration

- (NSDictionary *)cloudServiceUrls{
    NSParameterAssert(self.dictionary);
    NSDictionary *result = nil;
    @try {result =  [[self.dictionary objectForKey:kMCHComponentMap] objectForKey:kMCHCloudServiceUrls];} @catch (NSException *exception) {}
    NSParameterAssert(result);
    return result;
}

- (NSURL *)cloudServiceUrlForKey:(NSString *)key{
    NSDictionary *dictionary = [self cloudServiceUrls];
    return [self.class HTTPURLForKey:key inDictionary:dictionary];
}

- (NSURL *)authZeroURL{
    return [self cloudServiceUrlForKey:kMCHServiceAuth0Url];
}

- (NSURL *)serviceAuthUrl{
    return [self cloudServiceUrlForKey:kMCHServiceAuthUrl];
}

- (NSURL *)serviceDeviceURL{
    return [self cloudServiceUrlForKey:kMCHServiceDeviceUrl];
}

@end
