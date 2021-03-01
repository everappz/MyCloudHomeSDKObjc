//
//  MCHAppAuthProvider.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <AppAuth/AppAuth.h>
#import "MCHAppAuthProvider.h"
#import "MCHConstants.h"

NSString * const MCHAppAuthProviderDidChangeState = @"MCHAppAuthProviderDidChangeState";

@interface MCHAppAuthProvider()<OIDAuthStateChangeDelegate>

@property (atomic, assign) BOOL needsToCallStateDidChangeNotification;
@property (atomic, assign) NSInteger pendingRequestsCount;
@property (nonatomic, strong) OIDAuthState *authState;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy, nullable) NSDictionary *userInfo;
@property (nonatomic, copy, nullable) NSDictionary *refreshTokenParameters;

@end


@implementation MCHAppAuthProvider

- (instancetype)initWithIdentifier:(NSString *)identifier
                          userInfo:(NSDictionary *_Nullable)userInfo
                             state:(OIDAuthState *)authState
            refreshTokenParameters:(NSDictionary *_Nullable)refreshTokenParameters{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    if (authState == nil){
        return nil;
    }
    if (identifier == nil){
        return nil;
    }
    
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.userInfo = userInfo;
        self.refreshTokenParameters = refreshTokenParameters;
        self.authState = authState;
        self.authState.stateChangeDelegate = self;
        self.pendingRequestsCount = 0;
    }
    return self;
}

- (void)getAccessTokenWithCompletionBlock:(void (^)(NSString * _Nullable accessToken, NSError * _Nullable error))completion{
    self.pendingRequestsCount+=1;
    MCHMakeWeakSelf;
    [self.authState performActionWithFreshTokens:^(NSString * _Nullable accessToken, NSString * _Nullable idToken, NSError * _Nullable error) {
        if(completion){
            completion(accessToken,error);
        }
        weakSelf.pendingRequestsCount-=1;
        [weakSelf authStateActionDidComplete];
    } additionalRefreshParameters:self.refreshTokenParameters];
}

- (void)didChangeState:(OIDAuthState *)state{
    self.needsToCallStateDidChangeNotification = YES;
    if (self.pendingRequestsCount <= 0) {
        self.pendingRequestsCount = 0;
        [self postStateDidChangeNotificationIfNeeded];
    }
}

- (void)authStateActionDidComplete {
    [self postStateDidChangeNotificationIfNeeded];
}

- (void)postStateDidChangeNotificationIfNeeded {
    if (self.needsToCallStateDidChangeNotification) {
        self.needsToCallStateDidChangeNotification = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:MCHAppAuthProviderDidChangeState object:self];
    }
}

@end
