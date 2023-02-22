//
//  MCHAppAuthManager.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "MCHAppAuthManager.h"
#import "MCHAppAuthProvider.h"
#import "MCHAPIClient.h"
#import "MCHConstants.h"
#import "NSError+MCHSDK.h"
#import "MCHEndpointConfiguration.h"
#import "MCHNetworkClient.h"
#import "MCHAppAuthFlow.h"

@interface MCHAppAuthManager()

@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, copy) NSArray<NSString *> *scopes;
@property (nonatomic, strong) MCHAppAuthFlow *currentAuthorizationFlow;

@end


static MCHAppAuthManager *_sharedAuthManager = nil;

@implementation MCHAppAuthManager

+ (instancetype)sharedManager{
    NSParameterAssert(_sharedAuthManager!=nil);
    return _sharedAuthManager;
}

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI{
    _sharedAuthManager = [[MCHAppAuthManager alloc] initWithClientID:clientID
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI
                                                              scopes:[MCHAppAuthManager defaultScopes]];
}

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *>*)scopes{
    _sharedAuthManager = [[MCHAppAuthManager alloc] initWithClientID:clientID
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI
                                                              scopes:scopes];
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
                          scopes:(NSArray<NSString *> *)scopes
{
    NSParameterAssert(clientID);
    NSParameterAssert(clientSecret);
    NSParameterAssert(redirectURI);
    NSParameterAssert(scopes);
    self = [super init];
    if(self){
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.redirectURI = redirectURI;
        self.scopes = scopes;
    }
    return self;
}

- (MCHAppAuthFlow *)authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                webViewDidStartLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                               webViewDidFinishLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                               webViewDidFailWithErrorBlock:(MCHAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                            completionBlock:(MCHAppAuthManagerAuthorizationBlock)completionBlock
{
    if (self.currentAuthorizationFlow) {
        [self.currentAuthorizationFlow cancel];
        self.currentAuthorizationFlow = nil;
    }
    
    MCHAppAuthFlow *flow = [MCHAppAuthFlow new];
    flow.clientID = self.clientID;
    flow.clientSecret = self.clientSecret;
    flow.redirectURI = self.redirectURI;
    flow.scopes = self.scopes;
    
    flow.webView = webView;
    flow.webViewDidStartLoadingBlock = webViewDidStartLoadingBlock;
    flow.webViewDidFinishLoadingBlock = webViewDidFinishLoadingBlock;
    flow.webViewDidFailWithErrorBlock = webViewDidFailWithErrorBlock;
    flow.completionBlock = completionBlock;
    
    [flow start];
    self.currentAuthorizationFlow = flow;
    
    return flow;
}

@end

