//
//  ViewController.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "ViewController.h"
#import "MyCloudHomeAuthViewController.h"
#import "MyCloudHomeHelper.h"
#import "FolderContentViewController.h"
#import <MyCloudHomeSDKObjc/MyCloudHomeSDKObjc.h>


NSString * const MCHAuthKey = @"MCHAuthKey";


@interface ViewController ()<MyCloudHomeAuthViewControllerDelegate>

@property (nonatomic,strong)UIStackView *stackView;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authProviderDidChangeNotification:)
                                                 name:MCHAppAuthProviderDidChangeState
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)authProviderDidChangeNotification:(NSNotification *)notification
{
    MCHAppAuthProvider *provider = notification.object;
    NSParameterAssert([provider isKindOfClass:[MCHAppAuthProvider class]]);
    if([provider isKindOfClass:[MCHAppAuthProvider class]]){
        NSMutableDictionary *authResult = [[self loadAuth] mutableCopy];
        MCHAuthState *authState = provider.authState;
        NSParameterAssert(authState);
        if (authState) {
            NSData *authData = [NSKeyedArchiver archivedDataWithRootObject:authState
                                                     requiringSecureCoding:YES
                                                                     error:nil];
            NSParameterAssert(authData);
            [authResult setObject:authData?:[NSData data] forKey:MCHAuthDataKey];
        }
        [self saveAuth:authResult];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.stackView removeFromSuperview];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 20.0;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];
    [stackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40.0].active = YES;
    [stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40.0].active = YES;
    [stackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    self.stackView = stackView;
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:@"Start" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [startButton.titleLabel setFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold]];
    [startButton setBackgroundColor:[UIColor lightGrayColor]];
    [startButton addTarget:self action:@selector(actionStart:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:startButton];
    startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [startButton.widthAnchor constraintEqualToConstant:300.0].active = YES;
    
    
    if ([self loadAuth]!=nil){
        UIButton *usePreviousAuthButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [usePreviousAuthButton setTitle:@"Continue" forState:UIControlStateNormal];
        [usePreviousAuthButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [usePreviousAuthButton.titleLabel setFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold]];
        [usePreviousAuthButton setBackgroundColor:[UIColor lightGrayColor]];
        [usePreviousAuthButton addTarget:self action:@selector(actionContinue:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:usePreviousAuthButton];
        usePreviousAuthButton.translatesAutoresizingMaskIntoConstraints = NO;
        [usePreviousAuthButton.widthAnchor constraintEqualToConstant:300.0].active = YES;
    }
}

- (void)actionStart:(id)sender
{
    MyCloudHomeAuthViewController *authController = [MyCloudHomeAuthViewController new];
    authController.delegate = self;
    __weak typeof (authController) weakAuthViewController = authController;
    [self presentViewController:authController animated:YES completion:^{
        [weakAuthViewController start];
    }];
}

- (void)actionContinue:(id)sender
{
    NSDictionary *savedAuth = [self loadAuth];
    [self showFolderContentWithAuth:savedAuth];
}

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController
             didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
    });
}

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController
           didSuccessWithAuth:(NSDictionary *)auth
{
    [self saveAuth:auth];
    [self showFolderContentWithAuth:auth];
}

- (void)showFolderContentWithAuth:(NSDictionary *)auth
{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            NSString *userID = [auth objectForKey:MCHUserID];
            MCHAPIClient *client = [MyCloudHomeHelper createClientWithAuthData:auth];
            
            FolderContentViewController *contentViewController = [FolderContentViewController new];
            contentViewController.client = client;
            contentViewController.userID = userID;
            
            UINavigationController *flowNavigationController =
            [[UINavigationController alloc] initWithRootViewController:contentViewController];
            [weakSelf presentViewController:flowNavigationController
                                   animated:YES
                                 completion:nil];
        }];
    });
}

- (void)saveAuth:(NSDictionary *)auth
{
    if (auth) {
        [[NSUserDefaults standardUserDefaults] setObject:auth forKey:MCHAuthKey];
    }
    else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MCHAuthKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSDictionary *)loadAuth
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:MCHAuthKey];
}

@end
