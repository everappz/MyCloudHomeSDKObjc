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
#import <MyCloudHomeSDKObjc/MCHAppAuthManager.h>
#import <MyCloudHomeSDKObjc/MCHAPIClient.h>
#import <MyCloudHomeSDKObjc/MCHAppAuthProvider.h>
#import <MyCloudHomeSDKObjc/MCHConstants.h>
#import <MyCloudHomeSDKObjc/MCHUser.h>
#import <MyCloudHomeSDKObjc/MCHDevice.h>
#import <MyCloudHomeSDKObjc/MCHAPIClientCache.h>
#import <AppAuth/AppAuth.h>

@interface ViewController ()<MyCloudHomeAuthViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:@"Start" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [startButton.titleLabel setFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold]];
    [startButton setBackgroundColor:[UIColor whiteColor]];
    [startButton addTarget:self action:@selector(actionStart:) forControlEvents:UIControlEventTouchUpInside];
    [startButton setFrame:self.view.bounds];
    startButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:startButton];
}

- (void)actionStart:(id)sender{
    MyCloudHomeAuthViewController *authController = [MyCloudHomeAuthViewController new];
    authController.delegate = self;
    __weak typeof (authController) weakAuthViewController = authController;
    [self presentViewController:authController animated:YES completion:^{
        [weakAuthViewController start];
    }];
}

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController didFailWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
    });
}

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController didSuccessWithAuth:(NSDictionary *)auth{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            NSString *userID = [auth objectForKey:MCHUserID];
            MCHAPIClient *client = [MyCloudHomeHelper createClientWithAuthData:auth];
            
            FolderContentViewController *contentViewController = [FolderContentViewController new];
            contentViewController.client = client;
            contentViewController.userID = userID;

            UINavigationController *flowNavigationController = [[UINavigationController alloc] initWithRootViewController:contentViewController];
            [weakSelf presentViewController:flowNavigationController
                               animated:YES
                             completion:nil];
        }];
    });
}

@end
