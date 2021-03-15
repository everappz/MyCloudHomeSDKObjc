//
//  MCHAppAuthProvider.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHAppAuthProvider.h"
#import "MCHConstants.h"
#import "MCHNetworkClient.h"
#import "MCHAuthState.h"
#import "MCHAccessToken.h"
#import "NSError+MCHSDK.h"

NSString * const MCHAppAuthProviderDidChangeState = @"MCHAppAuthProviderDidChangeState";

@interface MCHAppAuthProvider()<MCHAuthStateChangeDelegate>

@property (nonatomic, strong) MCHAuthState *authState;

@property (nonatomic, copy) NSString *identifier;

@end




@implementation MCHAppAuthProvider

- (instancetype)initWithIdentifier:(NSString *)identifier
                             state:(MCHAuthState *)authState{
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
        self.authState = authState;
        self.authState.stateChangeDelegate = self;
    }
    return self;
}

- (void)getAccessTokenWithCompletionBlock:(MCHAccessTokenGetBlock)completion{
    NSString *accessToken = self.authState.accessToken;
    NSString *accessTokenType = self.authState.tokenType;
    NSError *tokenUpdateError = self.authState.tokenUpdateError;
    NSDate *tokenExpireDate = self.authState.tokenExpireDate;
    
    BOOL tokenExpired = NO;
    if (tokenExpireDate) {
        tokenExpired = (NSOrderedDescending == [[NSDate date] compare:tokenExpireDate]);
    }
    
    if (tokenExpired) {
        if (completion){
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeAccessTokenExpired]);
        }
        return;
    }
    
    if (tokenUpdateError) {
        if (completion){
            completion(nil,tokenUpdateError);
        }
        return;
    }
    
    MCHAccessToken *resultToken = [MCHAccessToken accessTokenWithToken:accessToken
                                                                  type:accessTokenType];
    
    if (resultToken == nil) {
        if (completion){
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAccessToken]);
        }
        return;
    }
    
    if (completion){
        completion(resultToken,nil);
    }
}

- (NSURLSessionDataTask * _Nullable)updateAccessTokenWithCompletionBlock:(MCHAccessTokenUpdateBlock)completion{
    return [self.authState updateTokenWithCompletion:completion];
}

- (void)MCHAuthStateDidChange:(MCHAuthState *)state{
    [[NSNotificationCenter defaultCenter] postNotificationName:MCHAppAuthProviderDidChangeState object:self];
}

@end
