//
//  MCHAuthorizationUserAgentWebView.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppAuth.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MCHAuthorizationUserAgentWebViewLoadingBlock)(WKWebView *webView);
typedef void(^MCHAuthorizationUserAgentWebViewErrorBlock)(WKWebView *webView, NSError *webViewError);

@interface MCHAuthorizationUserAgentWebView : NSObject<OIDExternalUserAgent>

- (instancetype)initWithWebView:(WKWebView *)webView
                    redirectURI:(NSURL *)redirectURI;

@property (nonatomic, weak, readonly) WKWebView *webView;
@property (nonatomic, strong, readonly) NSURL *redirectURI;
@property (nonatomic,copy)MCHAuthorizationUserAgentWebViewLoadingBlock webViewDidStartLoadingBlock;
@property (nonatomic,copy)MCHAuthorizationUserAgentWebViewLoadingBlock webViewDidFinishLoadingBlock;
@property (nonatomic,copy)MCHAuthorizationUserAgentWebViewErrorBlock webViewDidFailWithErrorBlock;

@end

NS_ASSUME_NONNULL_END
