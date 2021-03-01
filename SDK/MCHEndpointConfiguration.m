//
//  MCHEndpointConfiguration.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//


#import "MCHEndpointConfiguration.h"
#import "MCHConstants.h"


@interface MCHEndpointServerConfigurationModel : MCHObject

@end


@implementation MCHEndpointServerConfigurationModel

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

- (NSURL *)serviceDeviceURL{
    return [self cloudServiceUrlForKey:kMCHServiceDeviceUrl];
}

@end


@interface MCHEndpointConfigurationImplementation : NSObject <MCHEndpointConfiguration>

- (instancetype)initWithAuthZeroURL:(NSURL *)authZeroURL
                   serviceDeviceURL:(NSURL *)serviceDeviceURL;

@property (nonatomic,strong)NSURL *authZeroURL;

@property (nonatomic,strong)NSURL *serviceDeviceURL;

@end

@implementation MCHEndpointConfigurationImplementation

- (instancetype)initWithAuthZeroURL:(NSURL *)authZeroURL
                   serviceDeviceURL:(NSURL *)serviceDeviceURL{
    self = [super init];
    if(self){
        self.authZeroURL = authZeroURL;
        self.serviceDeviceURL = serviceDeviceURL;
    }
    return self;
}

@end


@implementation MCHEndpointConfigurationBuilder

+ (id<MCHEndpointConfiguration>)configurationWithDictionary:(NSDictionary * _Nonnull)dictionary{
    MCHEndpointServerConfigurationModel *endPointConfigurationServerModel =
    [[MCHEndpointServerConfigurationModel alloc] initWithDictionary:[dictionary objectForKey:kMCHData]];
    NSURL *authURL = endPointConfigurationServerModel.authZeroURL;
    NSURL *serviceDeviceURL = endPointConfigurationServerModel.serviceDeviceURL;
    id<MCHEndpointConfiguration> endPointConfiguration =
    [[MCHEndpointConfigurationImplementation alloc] initWithAuthZeroURL:authURL
                                                       serviceDeviceURL:serviceDeviceURL];
    
    return endPointConfiguration;
}

@end

