//
//  MCHAPIClientRequest.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import <Foundation/Foundation.h>
#import "MCHConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCHAPIClientCancellableRequest <NSObject>

- (void)cancel;

@end



@interface MCHAPIClientRequest : NSObject <MCHAPIClientCancellableRequest>

- (instancetype)initWithInternalRequest:(id<MCHAPIClientCancellableRequest> _Nullable)internalRequest;

@property (nonatomic, strong, nullable) id<MCHAPIClientCancellableRequest> internalRequest;
@property (nonatomic, copy, nullable) MCHAPIClientDidReceiveDataBlock didReceiveDataBlock;
@property (nonatomic, copy, nullable) MCHAPIClientDidReceiveResponseBlock didReceiveResponseBlock;
@property (nonatomic, copy, nullable) MCHAPIClientErrorCompletionBlock errorCompletionBlock;
@property (nonatomic, copy, nullable) MCHAPIClientProgressBlock progressBlock;
@property (nonatomic, copy, nullable) MCHAPIClientURLCompletionBlock downloadCompletionBlock;
@property (nonatomic , copy , nullable) MCHAPIClientVoidCompletionBlock cancelBlock;
@property (nonatomic, strong, nullable) NSNumber *totalContentSize;
@property (nonatomic, assign) NSUInteger URLTaskIdentifier;

- (BOOL)isCancelled;

@end


NS_ASSUME_NONNULL_END
