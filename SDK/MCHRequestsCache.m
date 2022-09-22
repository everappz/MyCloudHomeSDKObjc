//
//  MCHRequestsCache.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "MCHRequestsCache.h"
#import "MCHAPIClientRequest.h"

@interface MCHRequestsCache()

@property (nonatomic,strong)NSMutableArray<MCHAPIClientCancellableRequest> *cancellableRequests;

@property (nonatomic,strong)NSRecursiveLock *stateLock;

@end


@implementation MCHRequestsCache

- (instancetype)init {
    self = [super init];
    if(self){
        self.cancellableRequests = [NSMutableArray<MCHAPIClientCancellableRequest> new];
        self.stateLock = [NSRecursiveLock new];
    }
    return self;
}

- (MCHAPIClientRequest * _Nullable)cachedCancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier {
    __block MCHAPIClientRequest *clientRequest = nil;
    [self.stateLock lock];
    [self.cancellableRequests enumerateObjectsUsingBlock:^(id<MCHAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[MCHAPIClientRequest class]] &&
            ((MCHAPIClientRequest *)obj).URLTaskIdentifier == URLTaskIdentifier)
        {
            clientRequest = obj;
            *stop = YES;
        }
    }];
    [self.stateLock unlock];
    return clientRequest;
}

- (NSArray<MCHAPIClientRequest *> * _Nullable)allCachedCancellableRequestsWithURLTasks{
    NSMutableArray *result = [NSMutableArray new];
    [self.stateLock lock];
    for (id<MCHAPIClientCancellableRequest> obj in self.cancellableRequests) {
        if ([obj isKindOfClass:[MCHAPIClientRequest class]] &&
            ((MCHAPIClientRequest *)obj).URLTaskIdentifier > 0)
        {
            [result addObject:obj];
        }
    }
    [self.stateLock unlock];
    return result;
}

- (MCHAPIClientRequest *)createCachedCancellableRequest{
    MCHAPIClientRequest *clientRequest = [[MCHAPIClientRequest alloc] init];
    [self addCancellableRequestToCache:clientRequest];
    return clientRequest;
}

- (void)addCancellableRequestToCache:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]);
    if ([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)] == NO) {
        return;
    }
    [self.stateLock lock];
    [self.cancellableRequests addObject:request];
    NSParameterAssert(self.cancellableRequests.count < 100);
    MCHMakeWeakSelf;
    MCHMakeWeakReference(request);
    if ([request isKindOfClass:[MCHAPIClientRequest class]]) {
        [(MCHAPIClientRequest *)request setCancelBlock:^{
            [weakSelf removeCancellableRequestFromCache:weak_request];
        }];
    }
    [self.stateLock unlock];
}

- (void)removeCancellableRequestFromCache:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    if ([request isKindOfClass:[MCHAPIClientRequest class]]) {
        MCHAPIClientRequest *clientRequest = (MCHAPIClientRequest *)request;
        [self removeCancellableRequestFromCache:clientRequest.internalRequest];
    }
    
    if ([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]) {
        [self.stateLock lock];
        [self.cancellableRequests removeObject:request];
        [self.stateLock unlock];
    }
}

- (void)cancelAndRemoveAllCachedRequests {
    [self.stateLock lock];
    for (id<MCHAPIClientCancellableRequest>request in self.cancellableRequests) {
        [MCHRequestsCache removeCancelBlockForRequest:request];
        if ([request respondsToSelector:@selector(cancel)]) {
            [request cancel];
        }
    }
    [self.cancellableRequests removeAllObjects];
    [self.stateLock unlock];
}

+ (void)removeCancelBlockForRequest:(id)request {
    if ([request isKindOfClass:[MCHAPIClientRequest class]] == NO) {
        return;
    }
    MCHAPIClientRequest *clientRequest = (MCHAPIClientRequest *)request;
    [clientRequest setCancelBlock:nil];
    [MCHRequestsCache removeCancelBlockForRequest:clientRequest.internalRequest];
}

@end
