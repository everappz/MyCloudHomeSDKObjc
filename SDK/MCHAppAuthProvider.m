//
//  MCHAppAuthProvider.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <AppAuth/AppAuth.h>
#import "MCHAppAuthProvider.h"

NSString * const MCHAppAuthProviderDidChangeState = @"MCHAppAuthProviderDidChangeState";

@interface MCHAppAuthProvider()<OIDAuthStateChangeDelegate>

@property(nonatomic, strong) OIDAuthState *authState;
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *identifier;

@end


@implementation MCHAppAuthProvider

- (instancetype)initWithIdentifier:(NSString *)identifier accessToken:(NSString *)accessToken{
    self = [super init];
    if(self){
        NSParameterAssert(accessToken);
        self.accessToken = accessToken;
        self.identifier = identifier;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier state:(OIDAuthState *)authState{
    self = [super init];
    if(self){
        NSParameterAssert(authState);
        self.authState = authState;
        self.identifier = identifier;
        self.authState.stateChangeDelegate = self;
    }
    return self;
}

- (void)getAccessTokenWithCompletion:(void (^)(NSString *accessToken, NSError *error))completion{
    if(self.accessToken.length>0){
        if(completion){
            completion(self.accessToken,nil);
        }
    }
    else{
        [self.authState performActionWithFreshTokens:^(NSString *_Nullable accessToken,
                                                       NSString *_Nullable idToken,
                                                       NSError *_Nullable error) {
            if(completion){
                completion(accessToken,error);
            }
        }];
    }
}

- (void)didChangeState:(OIDAuthState *)state{
    [[NSNotificationCenter defaultCenter] postNotificationName:MCHAppAuthProviderDidChangeState object:self];
}

@end
