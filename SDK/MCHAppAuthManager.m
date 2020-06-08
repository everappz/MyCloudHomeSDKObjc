//
//  MCHAppAuthManager.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <AppAuth/AppAuth.h>
#import "MCHAppAuthManager.h"
#import "MCHAppAuthProvider.h"
#import "MCHAPIClient.h"
#import "MCHConstants.h"
#import "NSError+MCHSDK.h"
#import "MCHEndpointConfiguration.h"

NSString * const MCHAppAuthManagerAuthDidChange = @"MCHAppAuthManagerAuthDidChange";
NSString * const MCHAppAuthManagerAuthKey = @"MCHAppAuthManagerAuthKey";
NSString * const MCHAppAuthManagerErrorKey = @"MCHAppAuthManagerErrorKey";

@interface MCHAppAuthManager()

@property(nonatomic, copy) NSString *clientID;
@property(nonatomic, copy) NSString *clientSecret;
@property(nonatomic, copy) NSString *redirectURI;
@property(nonatomic, strong) NSArray *scopes;
@property(nonatomic, strong) MCHAPIClient *apiClient;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *authorizationRequestAdditionalParameters;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *tokenExchangeAdditionalParameters;
@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end


static MCHAppAuthManager *_sharedAuthManager = nil;

@implementation MCHAppAuthManager

+ (instancetype)sharedManager{
    NSParameterAssert(_sharedAuthManager!=nil);
    return _sharedAuthManager;
}

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *>*)scopes
      authorizationRequestParameters:(nullable NSDictionary<NSString *, NSString *> *)authorizationRequestAdditionalParameters
             tokenExchangeParameters:(nullable NSDictionary<NSString *, NSString *> *)tokenExchangeAdditionalParameters{
    _sharedAuthManager = [[MCHAppAuthManager alloc] initWithClientID:clientID
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI
                                                              scopes:scopes
                                      authorizationRequestParameters:authorizationRequestAdditionalParameters
                                             tokenExchangeParameters:tokenExchangeAdditionalParameters];
}

+ (NSDictionary<NSString *, NSString *> *)defaultTokenExchangeParameters {
    return @{@"audience": @"mycloud.com"};
}

+ (NSDictionary<NSString *, NSString *> *)defaultAuthorizationRequestParameters{
    return
    @{
        @"audience":@"mycloud.com",
        @"connection":@"Username-Password-Authentication",
        @"sso":@"false",
        @"protocol":@"oauth2"
    };
}

+ (NSArray<NSString *> *)defaultScopes {
    return @[@"nas_read_only",
             @"nas_read_write",
             @"openid",
             @"email",
             //@"profile",
             @"offline_access",
             @"device_read",
             @"user_read"];
}

- (instancetype)initWithClientID:(NSString *)clientID
                    clientSecret:(NSString *)clientSecret
                     redirectURI:(NSString *)redirectURI
                          scopes:(NSArray<NSString *>*)scopes
  authorizationRequestParameters:(nullable NSDictionary<NSString *, NSString *> *)authorizationRequestAdditionalParameters
         tokenExchangeParameters:(nullable NSDictionary<NSString *, NSString *> *)tokenExchangeAdditionalParameters{
    NSParameterAssert(clientID);
    NSParameterAssert(redirectURI);
    self = [super init];
    if(self){
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.redirectURI = redirectURI;
        self.scopes = scopes;
        self.authorizationRequestAdditionalParameters = authorizationRequestAdditionalParameters;
        self.tokenExchangeAdditionalParameters = tokenExchangeAdditionalParameters;
    }
    return self;
}

- (BOOL)applicationOpenURL:(NSURL *)url{
    if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
        _currentAuthorizationFlow = nil;
        return YES;
    }
    return NO;
}

- (OIDAuthorizationRequest *_Nullable)authorizationRequestWithAuthorizationEndpoint:(NSURL *_Nonnull)authURL
                                                                      tokenEndpoint:(NSURL *_Nonnull)tokenEndpoint{
    NSParameterAssert(authURL);
    NSParameterAssert(tokenEndpoint);
    NSURL *redirectURI = [NSURL URLWithString:self.redirectURI];
    if(authURL && tokenEndpoint && redirectURI){
        OIDServiceConfiguration *configuration = [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authURL
                                                                                                  tokenEndpoint:tokenEndpoint];
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:self.clientID
                                                  clientSecret:self.clientSecret
                                                        scopes:self.scopes
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:self.authorizationRequestAdditionalParameters];
        return request;
    }
    return nil;
}

- (void)authWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                webViewDidStartLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidStartLoadingBlock
               webViewDidFinishLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidFinishLoadingBlock
               webViewDidFailWithErrorBlock:(MCHAuthorizationUserAgentWebViewErrorBlock) webViewDidFailWithErrorBlock
                            completionBlock:(MCHAppAuthManagerAuthorizationCallback)completionBlock{
    
    NSCParameterAssert(webView);
    self.apiClient = [[MCHAPIClient alloc] initWithSessionConfiguration:nil endpointConfiguration:nil authProvider:nil];
    
    MCHMakeWeakSelf;
    [self.apiClient getEndpointConfigurationWithCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        MCHEndpointConfiguration *endPointConfiguration = [[MCHEndpointConfiguration alloc] initWithDictionary:[dictionary objectForKey:kMCHData]];
        NSURL *authZeroURL = [endPointConfiguration authZeroURL];
        
        if(authZeroURL){
            
            NSURL *authorizationEndpoint = [authZeroURL URLByAppendingPathComponent:kMCHAuthorize];
            NSURL *tokenEndpoint = [authZeroURL URLByAppendingPathComponent:kMCHOAuthToken];
            
            OIDAuthorizationRequest *authRequest = [strongSelf authorizationRequestWithAuthorizationEndpoint:authorizationEndpoint tokenEndpoint:tokenEndpoint];
            if(authRequest){
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.currentAuthorizationFlow =
                    [MCHAppAuthManager authStateByPresentingAuthorizationRequest:authRequest
                                                                         webView:(WKWebView *)webView
                                                                     redirectURI:[NSURL URLWithString:strongSelf.redirectURI] tokenExchangeParameters:strongSelf.tokenExchangeAdditionalParameters
                                                     webViewDidStartLoadingBlock:webViewDidStartLoadingBlock
                                                    webViewDidFinishLoadingBlock:webViewDidFinishLoadingBlock
                                                    webViewDidFailWithErrorBlock:webViewDidFailWithErrorBlock
                                                                 completionBlock:^(OIDAuthState *_Nullable authState, NSError *_Nullable error) {
                        if (authState) {
                            [strongSelf didCompleteAuthorization:authState error:nil];
                        } else {
                            [strongSelf didCompleteAuthorization:nil error:error];
                        }
                        if(completionBlock){
                            completionBlock(authState,endPointConfiguration,error);
                        }
                    }];
                });
            }
            else if (completionBlock){
                completionBlock(nil,nil,[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAuthURL]);
            }
            
        }
        else if (completionBlock){
            completionBlock(nil,nil,[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAuthURL]);
        }
    }];
}

+ (id<OIDExternalUserAgentSession>)authStateByPresentingAuthorizationRequest:(OIDAuthorizationRequest *)authorizationRequest
                                                                     webView:(WKWebView *)webView
                                                                 redirectURI:(NSURL *)redirectURI
                                                     tokenExchangeParameters:(nullable NSDictionary<NSString *, NSString *> *)tokenExchangeAdditionalParameters
                                                 webViewDidStartLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidStartLoadingBlock
                                                webViewDidFinishLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidFinishLoadingBlock
                                                webViewDidFailWithErrorBlock:(MCHAuthorizationUserAgentWebViewErrorBlock) webViewDidFailWithErrorBlock
                                                             completionBlock:(OIDAuthStateAuthorizationCallback)completionBlock{
    MCHAuthorizationUserAgentWebView *coordinator = [[MCHAuthorizationUserAgentWebView alloc] initWithWebView:webView redirectURI:redirectURI];
    coordinator.webViewDidStartLoadingBlock = webViewDidStartLoadingBlock;
    coordinator.webViewDidFinishLoadingBlock = webViewDidFinishLoadingBlock;
    coordinator.webViewDidFailWithErrorBlock = webViewDidFailWithErrorBlock;
    return [self authStateByPresentingAuthorizationRequest:authorizationRequest
                                         externalUserAgent:coordinator
                                   tokenExchangeParameters:tokenExchangeAdditionalParameters
                                                  callback:completionBlock];
}

+ (id<OIDExternalUserAgentSession>)authStateByPresentingAuthorizationRequest:(OIDAuthorizationRequest *)authorizationRequest
                                                           externalUserAgent:(id<OIDExternalUserAgent>)externalUserAgent
                                                     tokenExchangeParameters:(nullable NSDictionary<NSString *, NSString *> *)tokenExchangeAdditionalParameters
                                                                    callback:(OIDAuthStateAuthorizationCallback)callback {
    // presents the authorization request
    id<OIDExternalUserAgentSession> authFlowSession = [OIDAuthorizationService
                                                       presentAuthorizationRequest:authorizationRequest
                                                       externalUserAgent:externalUserAgent
                                                       callback:^(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                                                  NSError *_Nullable authorizationError) {
        // inspects response and processes further if needed (e.g. authorization
        // code exchange)
        if (authorizationResponse) {
            if ([authorizationRequest.responseType
                 isEqualToString:OIDResponseTypeCode]) {
                // if the request is for the code flow (NB. not hybrid), assumes the
                // code is intended for this client, and performs the authorization
                // code exchange
                OIDTokenRequest *tokenExchangeRequest =
                [authorizationResponse tokenExchangeRequestWithAdditionalParameters:tokenExchangeAdditionalParameters];
                [OIDAuthorizationService performTokenRequest:tokenExchangeRequest
                               originalAuthorizationResponse:authorizationResponse
                                                    callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                               NSError *_Nullable tokenError) {
                    OIDAuthState *authState;
                    if (tokenResponse) {
                        authState = [[OIDAuthState alloc]
                                     initWithAuthorizationResponse:
                                     authorizationResponse
                                     tokenResponse:tokenResponse];
                    }
                    callback(authState, tokenError);
                }];
            } else {
                // hybrid flow (code id_token). Two possible cases:
                // 1. The code is not for this client, ie. will be sent to a
                //    webservice that performs the id token verification and token
                //    exchange
                // 2. The code is for this client and, for security reasons, the
                //    application developer must verify the id_token signature and
                //    c_hash before calling the token endpoint
                OIDAuthState *authState = [[OIDAuthState alloc]
                                           initWithAuthorizationResponse:authorizationResponse];
                callback(authState, authorizationError);
            }
        } else {
            callback(nil, authorizationError);
        }
    }];
    return authFlowSession;
}

- (void)didCompleteAuthorization:(OIDAuthState *)authorization error:(NSError *)error{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if(authorization){
        [dictionary setObject:authorization forKey:MCHAppAuthManagerAuthKey];
    }
    if(error){
        [dictionary setObject:error forKey:MCHAppAuthManagerErrorKey];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MCHAppAuthManagerAuthDidChange
                                                            object:self
                                                          userInfo:dictionary];
    });
}

@end
