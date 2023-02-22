//
//  MCHAppAuthFlow.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "MCHAppAuthFlow.h"
#import "MCHAPIClient.h"
#import "MCHConstants.h"
#import "NSError+MCHSDK.h"
#import "MCHEndpointConfiguration.h"
#import "MCHNetworkClient.h"
#import "MCHAuthRequest.h"
#import "MCHAuthorizationWebViewCoordinator.h"
#import "MCHNetworkClient.h"
#import "MCHAuthState.h"

@interface MCHAppAuthFlow()

@property (atomic, assign) BOOL started;
@property (atomic, assign) BOOL cancelled;
@property (atomic, assign) BOOL completed;

@property (nonatomic, strong) MCHAPIClient *apiClient;
@property (nonatomic, strong) id<MCHEndpointConfiguration> endPointConfiguration;
@property (nonatomic, strong) MCHAuthorizationWebViewCoordinator *webViewCoordinator;
@property (nonatomic, strong) MCHNetworkClient *networkClient;
@property (nonatomic, weak) NSURLSessionDataTask *tokenExchangeDataTask;

@end



@implementation MCHAppAuthFlow

- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiClient = [[MCHAPIClient alloc] initWithURLSessionConfiguration:nil
                                                         endpointConfiguration:nil
                                                                  authProvider:nil];
        self.networkClient = [[MCHNetworkClient alloc] initWithURLSessionConfiguration:nil];
    }
    return self;
}

- (void)start {
    if (self.started){
        NSParameterAssert(NO);
        return;
    }
    
    self.started = YES;
    
    MCHMakeWeakSelf;
    [self.apiClient getEndpointConfigurationWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        
        id<MCHEndpointConfiguration> endPointConfiguration =
        [MCHEndpointConfigurationBuilder configurationWithDictionary:dictionary];
        strongSelf.endPointConfiguration = endPointConfiguration;
        
        NSURL *authZeroURL = endPointConfiguration.authZeroURL;
        NSCParameterAssert(authZeroURL);
        
        if(authZeroURL){
            
            NSURL *authorizationEndpoint = [authZeroURL URLByAppendingPathComponent:kMCHAuthorize];
            NSURL *tokenEndpoint = [authZeroURL URLByAppendingPathComponent:kMCHOAuthToken];
            NSURL *redirectURI = [NSURL URLWithString:strongSelf.redirectURI];
            
            MCHAuthStartRequest *authStartRequest = [MCHAuthStartRequest requestWithURL:authorizationEndpoint
                                                                               clientID:strongSelf.clientID
                                                                                 scopes:strongSelf.scopes
                                                                            redirectURL:redirectURI];
            
            NSURLRequest *authStartURLRequest = authStartRequest.URLRequest;
            
            if(authStartURLRequest){
                dispatch_async(dispatch_get_main_queue(), ^{
                    MCHAuthorizationWebViewCoordinator *coordinator =
                    [[MCHAuthorizationWebViewCoordinator alloc] initWithWebView:strongSelf.webView
                                                                    redirectURI:redirectURI];
                    coordinator.webViewDidStartLoadingBlock = strongSelf.webViewDidStartLoadingBlock;
                    coordinator.webViewDidFinishLoadingBlock = strongSelf.webViewDidFinishLoadingBlock;
                    coordinator.webViewDidFailWithErrorBlock = strongSelf.webViewDidFailWithErrorBlock;
                    coordinator.completionBlock = ^(WKWebView *webView, NSURL * _Nullable webViewRedirectURL, NSError * _Nullable error)
                    {
                        NSString *code = [MCHAppAuthFlow codeFromURL:webViewRedirectURL];
                        if (code) {
                            [strongSelf getTokenUsingURL:tokenEndpoint code:code];
                        }
                        else{
                            [strongSelf completeFlowWithAuthState:nil
                                            endpointConfiguration:nil
                                                            error:error];
                        }
                    };
                    strongSelf.webViewCoordinator = coordinator;
                    const BOOL presentUserAgentResult = [coordinator presentExternalUserAgentRequest:authStartURLRequest];
                    if (presentUserAgentResult == NO) {
                        [strongSelf completeFlowWithAuthState:nil
                                        endpointConfiguration:nil
                                                        error:[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAuthURL]];
                    }
                });
            }
            else {
                [strongSelf completeFlowWithAuthState:nil
                                endpointConfiguration:nil
                                                error:[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAuthURL]];
            }
        }
        else {
            [strongSelf completeFlowWithAuthState:nil
                            endpointConfiguration:nil
                                            error:[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAuthURL]];
        }
    }];
}

+ (NSString *_Nullable)codeFromURL:(NSURL *)URL{
    return [[MCHNetworkClient queryDictionaryFromURL:URL] objectForKey:@"code"];
}

- (void)getTokenUsingURL:(NSURL *)url
                    code:(NSString *)code{
    MCHTokenExchangeRequest *tokenExchangeRequest = [MCHTokenExchangeRequest requestWithURL:url
                                                                                   clientID:self.clientID
                                                                               clientSecret:self.clientSecret
                                                                                       code:code
                                                                                redirectURL:[NSURL URLWithString:self.redirectURI]];
    NSURLRequest *tokenExchangeURLRequest = [tokenExchangeRequest URLRequest];
    if (tokenExchangeURLRequest == nil) {
        [self completeFlowWithAuthState:nil
                  endpointConfiguration:nil
                                  error:[NSError MCHErrorWithCode:MCHErrorCodeCannotGetAccessToken]];
        return;
    }
    
    MCHMakeWeakSelf;
    NSURLSessionDataTask *tokenExchangeDataTask =
    [self.networkClient dataTaskWithRequest:tokenExchangeURLRequest
                          completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        MCHMakeStrongSelf;
        [MCHNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            if ([dictionary objectForKey:@"access_token"] == nil) {
                [strongSelf completeFlowWithAuthState:nil
                                endpointConfiguration:nil
                                                error:error];
            }
            else{
                [strongSelf tokenRequestDidCompleteWithDictionary:dictionary
                                                   tokenUpdateURL:url];
            }
        } withData:data response:response error:error];
    }];
    self.tokenExchangeDataTask = tokenExchangeDataTask;
    [tokenExchangeDataTask resume];
}

/*
 "access_token" = "";
 "expires_in" = 86400;
 "id_token" = "";
 "refresh_token" = "";
 scope = "openid email nas_read_write nas_read_only user_read device_read offline_access";
 "token_type" = Bearer;
 */
- (void)tokenRequestDidCompleteWithDictionary:(NSDictionary *)dictionary tokenUpdateURL:(NSURL *)tokenUpdateURL{
    NSString *access_token = [MCHObject stringForKey:@"access_token" inDictionary:dictionary];
    NSNumber *expires_in = [MCHObject numberForKey:@"expires_in" inDictionary:dictionary];
    NSString *id_token = [MCHObject stringForKey:@"id_token" inDictionary:dictionary];
    NSString *refresh_token = [MCHObject stringForKey:@"refresh_token" inDictionary:dictionary];
    //NSString *scope = [MCHObject stringForKey:@"scope" inDictionary:dictionary];
    NSString *token_type = [MCHObject stringForKey:@"token_type" inDictionary:dictionary];
    
    NSParameterAssert(access_token);
    NSParameterAssert(refresh_token);
    
    NSDate *tokenExpireDate = nil;
    if (expires_in && expires_in.longLongValue > 0){
        tokenExpireDate = [NSDate dateWithTimeIntervalSinceNow:expires_in.longLongValue];
    }
    
    MCHAuthState *authState = [[MCHAuthState alloc] initWithClientID:self.clientID
                                                        clientSecret:self.clientSecret
                                                         redirectURI:self.redirectURI
                                                              scopes:self.scopes
                                                         accessToken:access_token
                                                             idToken:id_token
                                                        refreshToken:refresh_token
                                                           tokenType:token_type
                                                           expiresIn:expires_in
                                                      tokenUpdateURL:tokenUpdateURL
                                                     tokenExpireDate:tokenExpireDate];
    
    [self completeFlowWithAuthState:authState
              endpointConfiguration:self.endPointConfiguration
                              error:nil];
}

- (void)completeFlowWithAuthState:(MCHAuthState *_Nullable)authState
            endpointConfiguration:(id<MCHEndpointConfiguration> _Nullable)endpointConfiguration
                            error:(NSError *_Nullable)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completed){
            NSParameterAssert(NO);
            return;
        }
        if (self.cancelled){
            return;
        }
        if (self.completionBlock){
            self.completionBlock(authState, endpointConfiguration, error);
        }
        [self cleanUp];
        self.completed = YES;
    });
}

- (void)cancel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cancelled){
            NSParameterAssert(NO);
            return;
        }
        [self.tokenExchangeDataTask cancel];
        [self cleanUp];
        self.cancelled = YES;
    });
}

- (void)cleanUp{
    NSParameterAssert([NSThread isMainThread]);
    [self.webViewCoordinator dismissExternalUserAgentAnimated:NO
                                                   completion:nil];
    self.webViewCoordinator = nil;
}

@end
