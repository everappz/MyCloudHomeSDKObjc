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

- (MCHAppAuthFlow *_Nullable )authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                          webViewDidStartLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                                         webViewDidFinishLoadingBlock:(MCHAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                                         webViewDidFailWithErrorBlock:(MCHAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                                      completionBlock:(MCHAppAuthManagerAuthorizationBlock)completionBlock;

@end


NS_ASSUME_NONNULL_END
