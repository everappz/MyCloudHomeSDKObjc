//
//  MCHAppAuthFlow.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "MCHConstants.h"


NS_ASSUME_NONNULL_BEGIN

@interface MCHAppAuthFlow : NSObject

@property(nonatomic, copy) NSString *clientID;
@property(nonatomic, copy) NSString *clientSecret;
@property(nonatomic, copy) NSString *redirectURI;
@property(nonatomic, copy) NSArray<NSString *> *scopes;

@property (nonatomic, weak, nullable) UIViewController *viewController;

@property (nonatomic, strong, nullable) WKWebView *webView;
@property (nonatomic, copy) MCHAuthorizationWebViewCoordinatorLoadingBlock webViewDidStartLoadingBlock;
@property (nonatomic, copy) MCHAuthorizationWebViewCoordinatorLoadingBlock webViewDidFinishLoadingBlock;
@property (nonatomic, copy) MCHAuthorizationWebViewCoordinatorErrorBlock webViewDidFailWithErrorBlock;
@property (nonatomic, copy) MCHAppAuthManagerAuthorizationBlock completionBlock;

- (void)start;

- (void)cancel;

- (void)handleRedirectURL:(NSURL *)redirectURL;

@end

NS_ASSUME_NONNULL_END
