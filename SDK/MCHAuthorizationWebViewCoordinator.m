//
//  MCHAuthorizationWebViewCoordinator.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <AuthenticationServices/AuthenticationServices.h>
#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>
#import "MCHAuthorizationWebViewCoordinator.h"
#import "MCHAppAuthManager.h"
#import "MCHConstants.h"
#import "NSError+MCHSDK.h"

typedef BOOL(^MCHAuthorizationWebViewDecidePolicyBlock)(WKWebView *webView,WKNavigationAction *navigationAction);

typedef void (^MCHAuthorizationWebViewCoordinatorAuthenticationServiceSuccessHandler)(NSURL *url);
typedef void (^MCHAuthorizationWebViewCoordinatorAuthenticationServiceFailureHandler)(NSError  * _Nullable error);


@interface MCHAuthorizationWebViewCoordinator()<WKNavigationDelegate, ASWebAuthenticationPresentationContextProviding>

@property (nonatomic, assign) BOOL authenticationSessionStarted;
@property (nonatomic, strong) SFSafariViewController *safariController;
@property (nonatomic, strong) ASWebAuthenticationSession *authenticationSession;
@property (nonatomic, assign) BOOL authorizationFlowInProgress;
@property (nonatomic, weak, nullable) WKWebView *webView;
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong) NSURL *redirectURI;
@property (nonatomic, copy) MCHAuthorizationWebViewDecidePolicyBlock webViewDecidePolicyBlock;

@end


@implementation MCHAuthorizationWebViewCoordinator

- (instancetype)initWithWebView:(WKWebView *)webView redirectURI:(NSURL *)redirectURI {
    self = [super init];
    if (self) {
        self.redirectURI = redirectURI;
        self.webView = webView;
        
        MCHMakeWeakSelf;
        [self setWebViewDecidePolicyBlock:^BOOL(WKWebView * _Nonnull webView, WKNavigationAction * _Nonnull navigationAction) {
            NSURL *navigationActionURL = navigationAction.request.URL;
            MCHLog(@"navigationActionURL: %@",navigationActionURL);
            if ([navigationActionURL.scheme.lowercaseString isEqualToString:redirectURI.scheme.lowercaseString]) {
                [weakSelf handleRedirectURL:navigationActionURL];
                return NO;
            }
            return YES;
        }];
    }
    return self;
}

- (instancetype)initWithViewController:(UIViewController *)viewController redirectURI:(NSURL *)redirectURI {
    self = [super init];
    if (self) {
        self.redirectURI = redirectURI;
        self.viewController = viewController;
    }
    return self;
}

- (void)failAuthorizationWithError:(NSError *)error {
    if (self.completionBlock) {
        self.completionBlock (nil,error);
    }
}

- (BOOL)presentExternalUserAgentRequest:(NSURLRequest *)request {
    NSParameterAssert([NSThread isMainThread]);
    if (self.authorizationFlowInProgress) {
        return NO;
    }
    self.authorizationFlowInProgress = YES;
    
    if (self.viewController) {
        MCHMakeWeakSelf;
        [self startAuthenticationServiceWithAuthorizationURL:request.URL 
                                           redirectURIScheme:self.redirectURI.scheme
                                              successHandler:^(NSURL *url) {
            [weakSelf handleRedirectURL:url];
        } failureHandler:^(NSError * _Nullable error) {
            if (weakSelf.completionBlock) {
                weakSelf.completionBlock(nil,error);
            }
        }];
        return YES;
    }
    else {
        NSParameterAssert(self.webView);
        NSParameterAssert(request);
        if (self.webView && request) {
            [self removeAllCookies];
            self.webView.navigationDelegate = self;
            [self.webView loadRequest:request];
            return YES;
        }
    }
    [self cleanUp];
    NSError *safariError = [NSError MCHErrorWithCode:MCHErrorCodeSafariOpenError];
    [self failAuthorizationWithError:safariError];
    return NO;
}

- (void)handleRedirectURL:(NSURL *)redirectURL {
    NSString *absoluteString = redirectURL.absoluteString;
    absoluteString = [absoluteString stringByReplacingOccurrencesOfString:@"/?" withString:@"?"];
    NSURL *fixedURL = [NSURL URLWithString:absoluteString];
    if (self.completionBlock) {
        self.completionBlock(fixedURL,nil);
    }
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion {
    NSParameterAssert([NSThread isMainThread]);
    if (!self.authorizationFlowInProgress) {
        return;
    }
    [self cleanUp];
    if (completion) {
        completion();
    }
}

- (void)cleanUp {
    self.webView.navigationDelegate = nil;
    self.webView = nil;
    self.authorizationFlowInProgress = NO;
    self.authenticationSessionStarted = NO;
    [self dismissAuthenticationServiceController];
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

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if(self.webViewDidStartLoadingBlock){
        self.webViewDidStartLoadingBlock(webView);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self WKWebViewDidFinish:webView error:nil];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self WKWebViewDidFinish:webView error:error];
}

#pragma mark - AuthenticationService

- (void)dismissAuthenticationServiceController {
    
    if (self.safariController != nil &&
        self.safariController.isBeingDismissed == NO &&
        self.viewController.presentedViewController == self.safariController)
    {
        [self.viewController dismissViewControllerAnimated:NO completion:nil];
        self.safariController = nil;
    }
    
    if (self.authenticationSession) {
        [self.authenticationSession cancel];
        self.authenticationSession = nil;
    }
}

// ASWebAuthenticationSession doesn't work with guided access (rdar://40809553)
- (BOOL)isWebAuthenticationSessionAvailable {
    return !UIAccessibilityIsGuidedAccessEnabled();
}

- (void)startAuthenticationServiceWithAuthorizationURL:(NSURL *)authorizationURL
                                     redirectURIScheme:(NSString *_Nullable)redirectURIScheme
                                        successHandler:(MCHAuthorizationWebViewCoordinatorAuthenticationServiceSuccessHandler)successHandler
                                        failureHandler:(MCHAuthorizationWebViewCoordinatorAuthenticationServiceFailureHandler)failureHandler
{
    if ([self isWebAuthenticationSessionAvailable]) {
        
        MCHMakeWeakSelf
        self.authenticationSession =
        [[ASWebAuthenticationSession alloc] initWithURL:authorizationURL
                                      callbackURLScheme:redirectURIScheme
                                      completionHandler:^(NSURL * _Nullable callbackURL,
                                                          NSError * _Nullable error) {
            MCHMakeStrongSelfAndReturnIfNil;
            
            NSLog(@"url: %@, error: %@",callbackURL,error);
            strongSelf.authenticationSession = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callbackURL) {
                    if (successHandler) {
                        successHandler(callbackURL);
                    }
                }
                else {
                    if (failureHandler) {
                        failureHandler(error);
                    }
                }
            });
        }];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
        if (@available(iOS 13.0, *)) {
            self.authenticationSession.presentationContextProvider = self;
            self.authenticationSession.prefersEphemeralWebBrowserSession = YES;
        }
#endif
        
        const BOOL started = [self.authenticationSession start];
        if (started) {
            self.authenticationSessionStarted = YES;
        }
        else {
            self.authenticationSession = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureHandler) {
                    failureHandler(nil);
                }
            });
        }
    }
    else {
        SFSafariViewControllerConfiguration *configuration = [[SFSafariViewControllerConfiguration alloc] init];
        SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:authorizationURL configuration:configuration];
        self.safariController = safariController;
        [self.viewController presentViewController:safariController animated:YES completion:nil];
    }
}

#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.viewController.view.window;
}

@end
