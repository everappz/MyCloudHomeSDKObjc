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
@class MCHAuthState;

@interface MCHAPIClientCache : NSObject

+ (instancetype)sharedCache;

- (MCHAPIClient *_Nullable)clientForIdentifier:(NSString *_Nonnull)identifier;

- (MCHAPIClient *_Nullable)createClientForIdentifier:(NSString *_Nonnull)identifier
                                           authState:(MCHAuthState *_Nonnull)authState
                                sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration;

- (void)authStateChanged:(MCHAuthState *_Nonnull)authState 
           forIdentifier:(NSString *_Nonnull)identifier;

@end

NS_ASSUME_NONNULL_END
