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

- (MCHAPIClientRequest * _Nullable)cachedCancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier;

- (NSArray<MCHAPIClientRequest *> * _Nullable)allCachedCancellableRequestsWithURLTasks;

- (MCHAPIClientRequest *)createCachedCancellableRequest;

- (void)addCancellableRequestToCache:(id<MCHAPIClientCancellableRequest> _Nonnull)request;

- (void)removeCancellableRequestFromCache:(id<MCHAPIClientCancellableRequest> _Nonnull)request;

- (void)cancelAndRemoveAllCachedRequests;

@end

NS_ASSUME_NONNULL_END
