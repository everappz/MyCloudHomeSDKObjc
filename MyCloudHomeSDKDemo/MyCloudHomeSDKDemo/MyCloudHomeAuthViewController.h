//
//  MyCloudHomeAuthViewController.h
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MCHAuthDataKey;
extern NSString * const MCHUserID;
extern NSString * const MCHClientID;

@class MyCloudHomeAuthViewController;

@protocol MyCloudHomeAuthViewControllerDelegate <NSObject>

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController didFailWithError:(NSError *)error;

- (void)MCHAuthViewController:(MyCloudHomeAuthViewController *)viewController didSuccessWithAuth:(NSDictionary *)auth;

@end


@interface MyCloudHomeAuthViewController : UIViewController

- (void)start;

@property (nonatomic,weak)id<MyCloudHomeAuthViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
