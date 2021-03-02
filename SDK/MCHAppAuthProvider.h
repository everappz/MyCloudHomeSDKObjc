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

extern NSString * const MCHAppAuthProviderUseCustomState;

@interface MCHAppAuthProvider : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier
                          userInfo:(NSDictionary *_Nullable)userInfo
                             state:(OIDAuthState *)authState
            refreshTokenParameters:(NSDictionary *_Nullable)refreshTokenParameters;

@property(nonatomic, strong, readonly) OIDAuthState *authState;
@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, copy, readonly, nullable) NSDictionary *userInfo;
@property(nonatomic, copy, readonly, nullable) NSDictionary *refreshTokenParameters;

- (void)getAccessTokenWithCompletionBlock:(void (^)(NSString * _Nullable accessToken, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
