//
//  MCHEndpointConfiguration.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCHObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCHEndpointConfiguration <NSObject>

- (NSURL *)authZeroURL;

- (NSURL *)serviceDeviceURL;

@end


@interface MCHEndpointConfigurationBuilder : NSObject

+ (nullable id<MCHEndpointConfiguration>)configurationWithDictionary:(NSDictionary * _Nonnull)dictionary;

@end


NS_ASSUME_NONNULL_END
