//
//  MCHAppAuthManager.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCHConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class MCHAppAuthFlow;

@interface MCHAppAuthManager : NSObject

+ (instancetype)sharedManager;

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI;

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *> *)scopes;

@property(nonatomic, copy, readonly) NSString *clientID;
@property(nonatomic, copy, readonly) NSString *clientSecret;
@property(nonatomic, copy, readonly) NSString *redirectURI;
@property(nonatomic, copy, readonly) NSArray<NSString *> *scopes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (MCHAppAuthFlow *_Nullable)authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                          webViewDidStartLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                                         webViewDidFinishLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                                         webViewDidFailWithErrorBlock:(MCHAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                                      completionBlock:(MCHAppAuthManagerAuthorizationBlock)completionBlock;

- (MCHAppAuthFlow *_Nullable)authFlowWithAutoCodeExchangeFromViewController:(UIViewController *)viewController
                                                      completionBlock:(MCHAppAuthManagerAuthorizationBlock)completionBlock;

//in AppDelegate
//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
//if ([[url absoluteString] hasPrefix:@"wd.com"]) {
//    NSCParameterAssert([MCHAppAuthManager sharedManager]);
//    [[MCHAppAuthManager sharedManager] handleRedirectURL:url];
//    return YES;
//}

- (void)handleRedirectURL:(NSURL *)url;

@end


NS_ASSUME_NONNULL_END
