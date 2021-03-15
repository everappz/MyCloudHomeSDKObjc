//
//  MCHAppAuthProvider.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCHConstants.h"


@class MCHAuthState;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MCHAppAuthProviderDidChangeState;

@interface MCHAppAuthProvider : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier
                             state:(MCHAuthState *)authState;

@property(nonatomic, strong, readonly) MCHAuthState *authState;

@property(nonatomic, copy, readonly) NSString *identifier;

- (void)getAccessTokenWithCompletionBlock:(MCHAccessTokenGetBlock)completion;

- (NSURLSessionDataTask * _Nullable)updateAccessTokenWithCompletionBlock:(MCHAccessTokenUpdateBlock)completion;

@end

NS_ASSUME_NONNULL_END
