//
//  MCHRequestsCache.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MCHAPIClientRequest;
@protocol MCHAPIClientCancellableRequest;

@interface MCHRequestsCache : NSObject

- (MCHAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier;

- (NSArray<MCHAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks;

- (MCHAPIClientRequest *)createAndAddCancellableRequest;

- (void)addCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request;

- (void)removeCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request;

@end

NS_ASSUME_NONNULL_END
