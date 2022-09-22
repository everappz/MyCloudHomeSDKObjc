//
//  MCHAPIClientRequest.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "MCHAPIClientRequest.h"

@interface MCHAPIClientRequest(){
    BOOL _сancelled;
    id<MCHAPIClientCancellableRequest> _Nullable _internalRequest;
}

@property (nonatomic, strong) NSRecursiveLock *stateLock;

@end



@implementation MCHAPIClientRequest

- (instancetype)initWithInternalRequest:(id<MCHAPIClientCancellableRequest> _Nullable)internalRequest{
    self = [super init];
    if (self) {
        self.stateLock = [NSRecursiveLock new];
        _internalRequest = internalRequest;
        _сancelled = NO;
    }
    return self;
}

- (void)cancel{
    [self.stateLock lock];
    _сancelled = YES;
    [_internalRequest cancel];
    [self.stateLock unlock];
    
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (BOOL)isCancelled{
    BOOL flag = NO;
    [self.stateLock lock];
    flag = _сancelled;
    [self.stateLock unlock];
    return flag;
}

- (void)setInternalRequest:(id<MCHAPIClientCancellableRequest> _Nullable)internalRequest {
    [self.stateLock lock];
    _internalRequest = internalRequest;
    [self.stateLock unlock];
}

- (id<MCHAPIClientCancellableRequest> _Nullable)internalRequest {
    id<MCHAPIClientCancellableRequest> internalRequest = nil;
    [self.stateLock lock];
    internalRequest = _internalRequest;
    [self.stateLock unlock];
    return internalRequest;
}

@end

