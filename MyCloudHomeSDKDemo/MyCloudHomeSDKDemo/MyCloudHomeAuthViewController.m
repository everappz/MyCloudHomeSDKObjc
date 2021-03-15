//
//  MyCloudHomeAuthViewController.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "MyCloudHomeAuthViewController.h"
#import "MyCloudHomeHelper.h"
#import <WebKit/WebKit.h>
#import <MyCloudHomeSDKObjc/MyCloudHomeSDKObjc.h>


@interface MyCloudHomeAuthViewController ()

@property (nonatomic,strong) MCHAPIClient *apiClient;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong) WKWebView *webView;

@end

@implementation MyCloudHomeAuthViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0];
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    @try{if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
        theConfiguration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    }} @catch(NSException *exc){}
    
    //scalesPageToFit script
    NSString *jScript = LS_WEB_VIEW_SCALE_TO_FIT_SCRIPT();
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    theConfiguration.userContentController = wkUController;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:theConfiguration];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0];
    [self.view addSubview:self.webView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

- (void)start{
    __weak typeof(self) weakSelf = self;
    
    
    [[MCHAppAuthManager sharedManager] authFlowWithAutoCodeExchangeFromWebView:self.webView
                                                   webViewDidStartLoadingBlock:^(WKWebView * _Nonnull webView) {
        [weakSelf.activityIndicator startAnimating];
    }
                                                  webViewDidFinishLoadingBlock:^(WKWebView * _Nonnull webView) {
        [weakSelf.activityIndicator stopAnimating];
    }
                                                  webViewDidFailWithErrorBlock:^(WKWebView * _Nonnull webView, NSError * _Nonnull webViewError) {
        [weakSelf.activityIndicator stopAnimating];
        [weakSelf completeWithError:webViewError];
    }
                                                               completionBlock:^(MCHAuthState * _Nullable authState, id<MCHEndpointConfiguration>  _Nullable endpointConfiguration, NSError * _Nullable error) {
        if(authState){
            MCHAppAuthProvider *authProvider =
            [[MCHAppAuthProvider alloc] initWithIdentifier:[MyCloudHomeHelper uuidString]
                                                     state:authState];
            weakSelf.apiClient =
            [[MCHAPIClient alloc] initWithURLSessionConfiguration:nil
                                            endpointConfiguration:endpointConfiguration
                                                     authProvider:authProvider];
            //delay to avoid 429 error code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.apiClient getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                    if(dictionary){
                        if(dictionary){
                            [weakSelf completeWithAuthState:authState
                                       userIDInfoDictionary:dictionary];
                        }
                        else{
                            [weakSelf completeWithError:error];
                        }
                    }
                    else{
                        [weakSelf completeWithError:error];
                    }
                }];
            });
        }
        else{
            [weakSelf completeWithError:error];
        }
    }];

}

- (void)completeWithError:(NSError *)error{
    if([self.delegate respondsToSelector:@selector(MCHAuthViewController:didFailWithError:)]){
        [self.delegate MCHAuthViewController:self didFailWithError:error];
    }
}

- (void)completeWithSuccess:(NSDictionary *)authData{
    if([self.delegate respondsToSelector:@selector(MCHAuthViewController:didSuccessWithAuth:)]){
        [self.delegate MCHAuthViewController:self didSuccessWithAuth:authData];
    }
}

- (void)completeWithAuthState:(MCHAuthState * _Nullable)authState
         userIDInfoDictionary:(NSDictionary * _Nullable)userIDInfoDictionary{
    MCHUser *user = [[MCHUser alloc] initWithDictionary:userIDInfoDictionary];
    NSString *userID = [user identifier];
    NSString *userEmail = [user email];
    NSParameterAssert(userID);
    NSParameterAssert(userEmail);
    NSMutableDictionary *authResult = [NSMutableDictionary new];
    if (userEmail) {
        [authResult setObject:userEmail forKey:MCHUserEmail];
    }
    if (userID) {
        [authResult setObject:userID forKey:MCHUserID];
    }
    if(authState){
        NSData *authData = [NSKeyedArchiver archivedDataWithRootObject:authState
                                                 requiringSecureCoding:YES
                                                                 error:nil];
        NSParameterAssert(authData);
        [authResult setObject:authData?:[NSData data] forKey:MCHAuthDataKey];
    }
    [self completeWithSuccess:authResult];
}

@end
