//
//  MCHAuthState.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import "MCHConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class MCHAuthState;

@protocol MCHAuthStateChangeDelegate <NSObject>

- (void)MCHAuthStateDidChange:(MCHAuthState *)state;

@end


@interface MCHAuthState : NSObject <NSSecureCoding>

- (instancetype)initWithClientID:(NSString * _Nullable)clientID
                    clientSecret:(NSString * _Nullable)clientSecret
                     redirectURI:(NSString * _Nullable)redirectURI
                          scopes:(NSArray<NSString *> * _Nullable)scopes
                     accessToken:(NSString * _Nullable)accessToken
                         idToken:(NSString * _Nullable)idToken
                    refreshToken:(NSString * _Nullable)refreshToken
                       tokenType:(NSString * _Nullable)tokenType
                       expiresIn:(NSNumber * _Nullable)expiresIn
                  tokenUpdateURL:(NSURL * _Nullable)tokenUpdateURL
                 tokenExpireDate:(NSDate * _Nullable)tokenExpireDate;

@property (atomic, copy, nullable) NSString *clientID;

@property (atomic, copy, nullable) NSString *clientSecret;

@property (atomic, copy, nullable) NSString *redirectURI;

@property (atomic, strong, nullable) NSArray<NSString *> *scopes;

@property (atomic, copy, nullable) NSString *accessToken;

@property (atomic, copy, nullable) NSString *idToken;

@property (atomic, copy, nullable) NSString *refreshToken;

@property (atomic, copy, nullable) NSString *tokenType;

@property (atomic, strong, nullable) NSNumber *expiresIn;

@property (atomic, strong, nullable) NSURL *tokenUpdateURL;

@property (atomic, strong, nullable) NSDate *tokenExpireDate;

@property (atomic, strong, nullable) NSError *tokenUpdateError;

@property (atomic, weak, nullable) id<MCHAuthStateChangeDelegate> stateChangeDelegate;

- (NSURLSessionDataTask *_Nullable)updateTokenWithCompletion:(MCHAccessTokenUpdateBlock)completion;

@end

NS_ASSUME_NONNULL_END
