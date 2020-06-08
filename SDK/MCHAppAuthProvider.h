//
//  MCHAppAuthProvider.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OIDAuthState;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MCHAppAuthProviderDidChangeState;

@interface MCHAppAuthProvider : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier state:(OIDAuthState *)authState;
- (instancetype)initWithIdentifier:(NSString *)identifier accessToken:(NSString *)accessToken;

@property(nonatomic, strong, readonly) OIDAuthState *authState;
@property(nonatomic, copy, readonly) NSString *accessToken;
@property(nonatomic, copy, readonly) NSString *identifier;

- (void)getAccessTokenWithCompletion:(void (^)(NSString *accessToken, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
