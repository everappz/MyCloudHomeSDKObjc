//
//  AppDelegate.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "AppDelegate.h"
#import <MyCloudHomeSDKObjc/MyCloudHomeSDKObjc.h>

//This temporary trial CSID is valid for short intervals of time and is changed regularly.
//It cannot be used as part of your released apps, since it will be disabled without notice and has a lifecycle of approximately 30 days:
//Please refer to the following page for more information on the My Cloud Home API:
//https://developer.westerndigital.com/develop/wd-my-cloud-home/api.html

#define APP_MYCLOUD_API_KEY                                     @"mSEJny79ckQzvSlRr9S55W8l30Do9bwI"
#define APP_MYCLOUD_SECRET_KEY                                  @"JIVemg3A0yEmbvkBGiS7RgnHEkq8veiNf6Rh-_gcNgZYNdJxrm5Z0anC76yfChhV"
#define APP_MYCLOUD_CALLBACK_URL                                @"http://localhost"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *myCloudHomeApiKey = APP_MYCLOUD_API_KEY;
    NSString *myCloudHomeSecretKey = APP_MYCLOUD_SECRET_KEY;
    NSString *myCloudHomeCallbackURL = APP_MYCLOUD_CALLBACK_URL;
    
    NSParameterAssert(myCloudHomeApiKey);
    NSParameterAssert(myCloudHomeSecretKey);
    
    if(myCloudHomeApiKey && myCloudHomeSecretKey){
        [MCHAppAuthManager setSharedManagerWithClientID:myCloudHomeApiKey
                                           clientSecret:myCloudHomeSecretKey
                                            redirectURI:myCloudHomeCallbackURL];
    }
    
    return YES;
}


#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

@end
