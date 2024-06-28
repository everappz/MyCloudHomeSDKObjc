//
//  MCHAuthorizationWebViewCoordinator.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "MCHConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCHAuthorizationWebViewCoordinator : NSObject

- (instancetype)initWithWebView:(WKWebView *)webView redirectURI:(NSURL *)redirectURI;
- (instancetype)initWithViewController:(UIViewController *)viewController redirectURI:(NSURL *)redirectURI;

@property (nonatomic, weak, readonly) WKWebView *webView;
@property (nonatomic, strong, readonly) NSURL *redirectURI;

@property (nonatomic,copy) MCHAuthorizationWebViewCoordinatorLoadingBlock webViewDidStartLoadingBlock;
@property (nonatomic,copy) MCHAuthorizationWebViewCoordinatorLoadingBlock webViewDidFinishLoadingBlock;
@property (nonatomic,copy) MCHAuthorizationWebViewCoordinatorErrorBlock webViewDidFailWithErrorBlock;

@property (nonatomic,copy) MCHAuthorizationWebViewCoordinatorCompletionBlock completionBlock;

- (BOOL)presentExternalUserAgentRequest:(NSURLRequest *)request;

- (void)dismissExternalUserAgentAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)handleRedirectURL:(NSURL *)redirectURL;

@end

NS_ASSUME_NONNULL_END
