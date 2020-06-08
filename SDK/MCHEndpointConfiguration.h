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

@interface MCHEndpointConfiguration : MCHObject

- (NSURL * _Nullable)authZeroURL;

- (NSURL * _Nullable)serviceAuthUrl;

- (NSURL * _Nullable)serviceDeviceURL;

@end

NS_ASSUME_NONNULL_END
