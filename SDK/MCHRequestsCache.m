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

@end


@implementation MCHRequestsCache

- (instancetype)init{
    self = [super init];
    if(self){
        self.cancellableRequests = [NSMutableArray<MCHAPIClientCancellableRequest> new];
    }
    return self;
}

- (MCHAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    __block MCHAPIClientRequest *clientRequest = nil;
    @synchronized (self.cancellableRequests) {
        [self.cancellableRequests enumerateObjectsUsingBlock:^(id<MCHAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[MCHAPIClientRequest class]] && ((MCHAPIClientRequest *)obj).URLTaskIdentifier==URLTaskIdentifier){
                clientRequest = obj;
                *stop = YES;
            }
        }];
    }
    return clientRequest;
}

- (NSArray<MCHAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    NSMutableArray *result = [NSMutableArray new];
    @synchronized (self.cancellableRequests) {
        [self.cancellableRequests enumerateObjectsUsingBlock:^(id<MCHAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[MCHAPIClientRequest class]] && ((MCHAPIClientRequest *)obj).URLTaskIdentifier>0){
                [result addObject:obj];
            }
        }];
    }
    return result;
}

- (MCHAPIClientRequest *)createAndAddCancellableRequest{
    MCHAPIClientRequest *clientRequest = [[MCHAPIClientRequest alloc] init];
    [self addCancellableRequest:clientRequest];
    return clientRequest;
}

- (void)addCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]);
    if([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]){
        @synchronized (self.cancellableRequests) {
            [self.cancellableRequests addObject:request];
        }
    }
}

- (void)removeCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert(request==nil || [request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]);
    if([request conformsToProtocol:@protocol(MCHAPIClientCancellableRequest)]){
        @synchronized (self.cancellableRequests) {
            [self.cancellableRequests removeObject:request];
        }
    }
}

@end
