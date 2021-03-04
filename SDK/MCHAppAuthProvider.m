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
#import "MCHNetworkClient.h"

NSString * const MCHAppAuthProviderDidChangeState = @"MCHAppAuthProviderDidChangeState";

@interface MCHAppAuthProvider()<OIDAuthStateChangeDelegate>

@property (atomic, assign) BOOL needsToCallStateDidChangeNotification;
@property (atomic, assign) NSInteger pendingRequestsCount;
@property (nonatomic, strong) OIDAuthState *authState;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy, nullable) NSDictionary *userInfo;
@property (nonatomic, copy, nullable) NSDictionary *refreshTokenParameters;

@end


@interface MCHOIDTokenRequest : OIDTokenRequest

@property (nonatomic,copy)NSString *MCHAccessToken;


@end

@interface MCHOIDAuthState : OIDAuthState

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
        MCHOIDAuthState *customState =
        [[MCHOIDAuthState alloc] initWithAuthorizationResponse:authState.lastAuthorizationResponse
                                                 tokenResponse:authState.lastTokenResponse];
        self.authState = customState;
        self.authState.stateChangeDelegate = self;
        self.pendingRequestsCount = 0;
    }
    return self;
}

- (void)getAccessTokenWithCompletionBlock:(void (^)(NSString * _Nullable accessToken, NSError * _Nullable error))completion{
    self.pendingRequestsCount+=1;
    MCHMakeWeakSelf;
    [self.authState performActionWithFreshTokens:
     ^(NSString * _Nullable accessToken, NSString * _Nullable idToken, NSError * _Nullable error) {
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


@implementation MCHOIDTokenRequest

- (NSURLRequest *)URLRequest {
    NSURL *tokenRequestURL = self.configuration.tokenEndpoint;
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:tokenRequestURL] mutableCopy];
    URLRequest.HTTPMethod = @"POST";
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [URLRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.MCHAccessToken] forHTTPHeaderField:@"Authorization"];
    
    NSMutableDictionary *bodyParams = [NSMutableDictionary new];
    if (self.clientID) {
        [bodyParams setObject:self.clientID forKey:@"client_id"];
    }
    if (self.grantType) {
        [bodyParams setObject:self.grantType forKey:@"grant_type"];
    }
    if (self.refreshToken) {
        [bodyParams setObject:self.refreshToken forKey:@"refresh_token"];
    }
    if (self.clientSecret) {
        [bodyParams setObject:self.clientSecret forKey:@"client_secret"];
    }
    if (self.additionalParameters){
        [bodyParams addEntriesFromDictionary:self.additionalParameters];
    }
    
    NSData *body = [MCHNetworkClient createJSONBodyWithParameters:bodyParams];
    [URLRequest setHTTPBody:body];
    [URLRequest addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
    [MCHNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end



@implementation MCHOIDAuthState

- (OIDTokenRequest *)tokenRefreshRequestWithAdditionalParameters:
(NSDictionary<NSString *, NSString *> *)additionalParameters {
    MCHOIDTokenRequest *tokenRefreshRequest =
    [[MCHOIDTokenRequest alloc]
     initWithConfiguration:self.lastAuthorizationResponse.request.configuration
     grantType:OIDGrantTypeRefreshToken
     authorizationCode:nil
     redirectURL:nil
     clientID:self.lastAuthorizationResponse.request.clientID
     clientSecret:self.lastAuthorizationResponse.request.clientSecret
     scope:nil
     refreshToken:self.refreshToken
     codeVerifier:nil
     additionalParameters:additionalParameters];
    tokenRefreshRequest.MCHAccessToken = self.MCHAccessToken;
    return tokenRefreshRequest;
}

- (NSString *)MCHAccessToken {
    return self.lastTokenResponse ? self.lastTokenResponse.accessToken : self.lastAuthorizationResponse.accessToken;
}

@end
