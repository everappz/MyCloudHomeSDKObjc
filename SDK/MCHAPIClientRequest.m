//
//  MCHAPIClientRequest.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "MCHAPIClientRequest.h"

@interface MCHAPIClientRequest(){
    BOOL _сancelled;
}

@end



@implementation MCHAPIClientRequest

- (instancetype)initWithInternalRequest:(id<MCHAPIClientCancellableRequest> _Nullable)internalRequest{
    self = [super init];
    if(self){
        self.internalRequest = internalRequest;
    }
    return self;
}

- (void)cancel{
    [self.internalRequest cancel];
    @synchronized(self){
        _сancelled = YES;
    }
}

- (BOOL)isCancelled{
    BOOL flag = NO;
    @synchronized(self){
        flag = _сancelled;
    }
    return flag;
}

@end

