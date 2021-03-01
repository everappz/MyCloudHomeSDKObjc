//
//  MCHAuthorizationUserAgentWebView.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHAuthorizationUserAgentWebView.h"
#import "OIDAuthorizationService.h"
#import "OIDErrorUtilities.h"
#import "MCHAppAuthManager.h"

typedef BOOL(^MCHAuthorizationUserAgentWebViewDecidePolicyBlock)(WKWebView *webView,WKNavigationAction *navigationAction);

@interface MCHAuthorizationUserAgentWebView()<WKNavigationDelegate>{
    BOOL _authorizationFlowInProgress;
    __weak id<OIDExternalUserAgentSession> _session;
}

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSURL *redirectURI;
@property (nonatomic, copy) MCHAuthorizationUserAgentWebViewDecidePolicyBlock webViewDecidePolicyBlock;

@end


@implementation MCHAuthorizationUserAgentWebView

- (instancetype)initWithWebView:(WKWebView *)webView
                    redirectURI:(NSURL *)redirectURI{
    self = [super init];
    if(self){
        _webView = webView;
        [self setWebViewDecidePolicyBlock:^BOOL(WKWebView * _Nonnull webView, WKNavigationAction * _Nonnull navigationAction) {
            NSURL *navigationActionURL = navigationAction.request.URL;
            NSLog(@"navigationActionURL: %@",navigationActionURL);
            if([navigationActionURL.scheme.lowercaseString isEqualToString:redirectURI.scheme.lowercaseString]){
                NSString *absoluteString = navigationActionURL.absoluteString;
                absoluteString = [absoluteString stringByReplacingOccurrencesOfString:@"/?" withString:@"?"];
                NSURL *fixedURL = [NSURL URLWithString:absoluteString];
                [[MCHAppAuthManager sharedManager] applicationOpenURL:fixedURL];
                return NO;
            }
            return YES;
        }];
    }
    return self;
}

#pragma mark - OIDExternalUserAgent

- (BOOL)presentExternalUserAgentRequest:(id<OIDExternalUserAgentRequest>)request
                                session:(id<OIDExternalUserAgentSession>)session {
    if (_authorizationFlowInProgress) {
        return NO;
    }
    _authorizationFlowInProgress = YES;
    _session = session;
    NSParameterAssert(self.webView);
    NSURL *URL = [request externalUserAgentRequestURL];
    NSParameterAssert(URL);
    if (_webView && URL) {
        [self removeAllCookies];
        _webView.navigationDelegate = self;
        [_webView loadRequest:[NSURLRequest requestWithURL:URL]];
        return YES;
    }
    [self cleanUp];
    NSError *safariError = [OIDErrorUtilities errorWithCode:OIDErrorCodeSafariOpenError
                                            underlyingError:nil
                                                description:@"Unable to open WKWebView."];
    [session failExternalUserAgentFlowWithError:safariError];
    return NO;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated completion:(void (^)(void))completion {
    if (!_authorizationFlowInProgress) {
        return;
    }
    [self cleanUp];
    if(completion){
        completion();
    }
}

- (void)cleanUp {
    _webView.navigationDelegate = nil;
    _webView = nil;
    _session = nil;
    _authorizationFlowInProgress = NO;
}

#pragma mark - WKWebView

- (void)WKWebViewDidFinish:(WKWebView *)webView error:(NSError *)webViewError {
    
    if (webView != _webView) {
        return;
    }
    
    if(webViewError && _authorizationFlowInProgress){
        id<OIDExternalUserAgentSession> session = _session;
        [self cleanUp];
        NSError *error = [OIDErrorUtilities errorWithCode:OIDErrorCodeProgramCanceledAuthorizationFlow
                                          underlyingError:nil
                                              description:nil];
        [session failExternalUserAgentFlowWithError:error];
    }
    
    if(webViewError){
        if(self.webViewDidFailWithErrorBlock){
            self.webViewDidFailWithErrorBlock(webView,webViewError);
        }
    }
    else{
        if(self.webViewDidFinishLoadingBlock){
            self.webViewDidFinishLoadingBlock(webView);
        }
    }
}

- (void)removeAllCookies{
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes
                                                   modifiedSince:dateFrom
                                               completionHandler:^{}];
    }
}

#pragma mark - WKNavigationDelegate Delegate

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if(decisionHandler){
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if(self.webViewDecidePolicyBlock){
        BOOL result = self.webViewDecidePolicyBlock(webView,navigationAction);
        if(result){
            if(decisionHandler){
                decisionHandler(WKNavigationActionPolicyAllow);
            }
        }
        else{
            if(decisionHandler){
                decisionHandler(WKNavigationActionPolicyCancel);
            }
        }
    }
    else{
        if(decisionHandler){
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }
}

- (void)webView:(WKWebView *)webView
didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    if(self.webViewDidStartLoadingBlock){
        self.webViewDidStartLoadingBlock(webView);
    }
}

- (void)webView:(WKWebView *)webView
didFinishNavigation:(null_unspecified WKNavigation *)navigation{
    [self WKWebViewDidFinish:webView error:nil];
}

- (void)webView:(WKWebView *)webView
didFailNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error{
    [self WKWebViewDidFinish:webView error:error];
}

@end
