//
//  MCHAuthorizationWebViewCoordinator.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "MCHAuthorizationWebViewCoordinator.h"
#import "MCHAppAuthManager.h"
#import "MCHConstants.h"
#import "NSError+MCHSDK.h"

typedef BOOL(^MCHAuthorizationWebViewDecidePolicyBlock)(WKWebView *webView,WKNavigationAction *navigationAction);

@interface MCHAuthorizationWebViewCoordinator()<WKNavigationDelegate>

@property (nonatomic, assign) BOOL authorizationFlowInProgress;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSURL *redirectURI;
@property (nonatomic, copy) MCHAuthorizationWebViewDecidePolicyBlock webViewDecidePolicyBlock;

@end


@implementation MCHAuthorizationWebViewCoordinator

- (instancetype)initWithWebView:(WKWebView *)webView
                    redirectURI:(NSURL *)redirectURI{
    self = [super init];
    if(self){
        self.webView = webView;
        MCHMakeWeakSelf;
        [self setWebViewDecidePolicyBlock:^BOOL(WKWebView * _Nonnull webView, WKNavigationAction * _Nonnull navigationAction) {
            NSURL *navigationActionURL = navigationAction.request.URL;
            NSLog(@"navigationActionURL: %@",navigationActionURL);
            if([navigationActionURL.scheme.lowercaseString isEqualToString:redirectURI.scheme.lowercaseString]){
                NSString *absoluteString = navigationActionURL.absoluteString;
                absoluteString = [absoluteString stringByReplacingOccurrencesOfString:@"/?" withString:@"?"];
                NSURL *fixedURL = [NSURL URLWithString:absoluteString];
                if (weakSelf.completionBlock) {
                    weakSelf.completionBlock(webView,fixedURL,nil);
                }
                return NO;
            }
            return YES;
        }];
    }
    return self;
}

- (void)failAuthorizationWithError:(NSError *)error {
    if (self.completionBlock) {
        self.completionBlock (self.webView,nil,error);
    }
}

- (BOOL)presentExternalUserAgentRequest:(NSURLRequest *)request {
    NSParameterAssert([NSThread isMainThread]);
    if (self.authorizationFlowInProgress) {
        return NO;
    }
    self.authorizationFlowInProgress = YES;
    NSParameterAssert(self.webView);
    NSParameterAssert(request);
    if (self.webView && request) {
        [self removeAllCookies];
        self.webView.navigationDelegate = self;
        [self.webView loadRequest:request];
        return YES;
    }
    [self cleanUp];
    NSError *safariError = [NSError MCHErrorWithCode:MCHErrorCodeSafariOpenError];
    [self failAuthorizationWithError:safariError];
    return NO;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated
                              completion:(nullable dispatch_block_t)completion
{
    NSParameterAssert([NSThread isMainThread]);
    if (!self.authorizationFlowInProgress) {
        return;
    }
    [self cleanUp];
    if(completion){
        completion();
    }
}

- (void)cleanUp {
    self.webView.navigationDelegate = nil;
    self.webView = nil;
    self.authorizationFlowInProgress = NO;
}

#pragma mark - WKWebView

- (void)WKWebViewDidFinish:(WKWebView *)webView error:(NSError *)webViewError {
    
    if (webView != self.webView) {
        return;
    }
    
    NSInteger code = [webViewError code];
    NSString *domain = [webViewError domain];
    
    if ([domain isEqualToString:NSURLErrorDomain]) {
        if (code == NSURLErrorCancelled){
            return;
        }
    } else if ([domain isEqualToString:@"WebKitErrorDomain"]) {
        if (code == 101){
            return;
        }
        if (code == 102){
            return;
        }
    }
    
    if(webViewError && self.authorizationFlowInProgress){
        [self cleanUp];
        NSError *error = [NSError MCHErrorWithCode:MCHErrorCodeCanceledAuthorizationFlow];
        [self failAuthorizationWithError:error];
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
