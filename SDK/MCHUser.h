//
//  MCHUser.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MCHUserApiKeyIdentifier;
extern NSString * const MCHUserApiKeyEmail;

@interface MCHUser : MCHObject

- (NSString * _Nullable)identifier;

- (NSString * _Nullable)email;

@end

NS_ASSUME_NONNULL_END
