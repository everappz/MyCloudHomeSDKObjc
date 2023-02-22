//
//  MCHAPIClientRequest.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "MCHAPIClientRequest.h"

@interface MCHAPIClientRequest(){
    BOOL _сancelled;
    id<MCHAPIClientCancellableRequest> _Nullable _childRequest;
}

@property (nonatomic, strong) NSRecursiveLock *stateLock;

@end



@implementation MCHAPIClientRequest

- (instancetype)init{
    self = [super init];
    if (self) {
        self.stateLock = [NSRecursiveLock new];
    }
    return self;
}

- (void)cancel{
    MCHAPIClientRequest *strongSelf = self;
    
    [strongSelf.stateLock lock];
    _сancelled = YES;
    [_childRequest cancel];
    [strongSelf.stateLock unlock];
    
    if (strongSelf.cancelBlock) {
        strongSelf.cancelBlock();
    }
}

- (BOOL)isCancelled{
    BOOL flag = NO;
    [self.stateLock lock];
    flag = _сancelled;
    [self.stateLock unlock];
    return flag;
}

- (void)setChildRequest:(id<MCHAPIClientCancellableRequest> _Nullable)childRequest {
    [self.stateLock lock];
    if ([childRequest isKindOfClass:[NSURLSessionTask class]]) {
        NSURLSessionTask *sessionTask = (NSURLSessionTask *)childRequest;
        _URLTaskIdentifier = [sessionTask taskIdentifier];
        NSParameterAssert(_URLTaskIdentifier > 0);
    }
    _childRequest = childRequest;
    [self.stateLock unlock];
}

- (id<MCHAPIClientCancellableRequest> _Nullable)childRequest {
    id<MCHAPIClientCancellableRequest> childRequest = nil;
    [self.stateLock lock];
    childRequest = _childRequest;
    [self.stateLock unlock];
    return childRequest;
}

@end

