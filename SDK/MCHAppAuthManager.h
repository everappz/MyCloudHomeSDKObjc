//
//  MCHAppAuthManager.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCHAuthorizationUserAgentWebView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MCHAppAuthManagerAuthDidChange;
extern NSString * const MCHAppAuthManagerAuthKey;
extern NSString * const MCHAppAuthManagerErrorKey;

@class WKWebView;
@class MCHEndpointConfiguration;
@class OIDAuthState;

typedef void (^MCHAppAuthManagerAuthorizationCallback)(OIDAuthState *_Nullable authState,
                                                       MCHEndpointConfiguration *_Nullable endpointConfiguration,
                                                       NSError *_Nullable error);

@interface MCHAppAuthManager : NSObject

+ (instancetype)sharedManager;

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *>*)scopes
      authorizationRequestParameters:(nullable NSDictionary<NSString *, NSString *> *)authorizationRequestAdditionalParameters
             tokenExchangeParameters:(nullable NSDictionary<NSString *, NSString *> *)tokenExchangeAdditionalParameters;

+ (NSDictionary<NSString *, NSString *> *)defaultTokenExchangeParameters;
+ (NSDictionary<NSString *, NSString *> *)defaultAuthorizationRequestParameters;
+ (NSArray<NSString *> *)defaultScopes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)applicationOpenURL:(NSURL *)url;

- (void)authWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                webViewDidStartLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidStartLoadingBlock
               webViewDidFinishLoadingBlock:(MCHAuthorizationUserAgentWebViewLoadingBlock) webViewDidFinishLoadingBlock
               webViewDidFailWithErrorBlock:(MCHAuthorizationUserAgentWebViewErrorBlock) webViewDidFailWithErrorBlock
                            completionBlock:(MCHAppAuthManagerAuthorizationCallback)completionBlock;

@end


NS_ASSUME_NONNULL_END
