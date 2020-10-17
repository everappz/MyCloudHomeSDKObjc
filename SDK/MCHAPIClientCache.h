//
//  MCHAPIClientCache.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/20/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MCHAPIClient;
@class OIDAuthState;

@interface MCHAPIClientCache : NSObject

+ (instancetype)sharedCache;

- (MCHAPIClient *_Nullable)clientForIdentifier:(NSString *_Nonnull)identifier 
                                     authState:(OIDAuthState *_Nonnull)authState
                          sessionConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

- (void)authStateChanged:(OIDAuthState *_Nonnull)authState 
           forIdentifier:(NSString *_Nonnull)identifier;

@end

NS_ASSUME_NONNULL_END
