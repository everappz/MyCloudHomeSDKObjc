//
//  MCHAPIClient.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHAPIClient.h"
#import "MCHConstants.h"
#import "MCHAppAuthProvider.h"
#import "MCHEndpointConfiguration.h"
#import "NSError+MCHSDK.h"
#import "MCHFile.h"
#import "MCHUser.h"
#import "NSError+MCHSDK.h"

NSTimeInterval const kMCHAPIClientRequestRetryTimeout = 1.5;

typedef void(^MCHAPIClientEndpointAndAccessTokenCompletionBlock)(id<MCHEndpointConfiguration> _Nullable endpointConfiguration,
                                                                 NSString * _Nullable accessToken,
                                                                 NSError * _Nullable error);

@interface MCHAPIClientRequest(){
    BOOL _сancelled;
}

@property (nonatomic,strong)id<MCHAPIClientCancellableRequest> internalRequest;
@property (nonatomic,copy,nullable)MCHAPIClientDidReceiveDataBlock didReceiveDataBlock;
@property (nonatomic,copy,nullable)MCHAPIClientDidReceiveResponseBlock didReceiveResponseBlock;
@property (nonatomic,copy,nullable)MCHAPIClientErrorCompletionBlock errorCompletionBlock;
@property (nonatomic,copy,nullable)MCHAPIClientProgressBlock progressBlock;
@property (nonatomic,copy,nullable)MCHAPIClientURLCompletionBlock downloadCompletionBlock;
@property (nonatomic,strong,nullable)NSNumber *totalContentSize;
@property (nonatomic,assign)NSUInteger URLTaskIdentifier;

@end


@interface MCHAPIClient()
<
NSURLSessionTaskDelegate,
NSURLSessionDelegate,
NSURLSessionDataDelegate,
NSURLSessionDownloadDelegate
>

@property (nonatomic,strong)NSOperationQueue *callbackQueue;
@property (nonatomic,strong)NSURLSession *session;
@property (nonatomic,strong,nullable)id<MCHEndpointConfiguration> endpointConfiguration;
@property (nonatomic,strong,nullable)MCHAppAuthProvider *authProvider;
@property (nonatomic,strong,nullable)NSDictionary *userInfo;
@property (nonatomic,strong)NSMutableArray<MCHAPIClientCancellableRequest> *cancellableRequests;

@end



@implementation MCHAPIClient


- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                          endpointConfiguration:(id<MCHEndpointConfiguration> _Nullable)endpointConfiguration
                                   authProvider:(MCHAppAuthProvider *_Nullable)authProvider{
    
    self = [super init];
    if(self){
        NSURLSessionConfiguration *resultConfiguration = URLSessionConfiguration;
        if(resultConfiguration == nil){
            resultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            resultConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
            resultConfiguration.allowsCellularAccess = YES;
            resultConfiguration.timeoutIntervalForRequest = 30;
            resultConfiguration.HTTPMaximumConnectionsPerHost = 1;
        }
        self.callbackQueue = [[NSOperationQueue alloc] init];
        self.callbackQueue.maxConcurrentOperationCount = 1;
        self.session = [NSURLSession sessionWithConfiguration:resultConfiguration
                                                     delegate:self
                                                delegateQueue:self.callbackQueue];
        self.endpointConfiguration = endpointConfiguration;
        self.authProvider = authProvider;
        self.userInfo = nil;
        self.cancellableRequests = [NSMutableArray<MCHAPIClientCancellableRequest> new];
    }
    return self;
}

- (void)updateAuthProvider:(MCHAppAuthProvider *_Nullable)authProvider{
    @synchronized (self) {
        self.authProvider = authProvider;
    }
}

#pragma mark - Public

- (id<MCHAPIClientCancellableRequest>)getEndpointConfigurationWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getEndpointConfigurationWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getEndpointConfigurationWithCompletionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getEndpointConfigurationWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    NSMutableURLRequest *request = [self GETRequestWithURL:[NSURL URLWithString:kMCHClientConfigURL]
                                               contentType:kMCHContentTypeApplicationJSON
                                               accessToken:nil];
    [MCHAPIClient printRequest:request];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                         completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        [MCHAPIClient processDictionaryCompletion:completion
                                         withData:data
                                         response:response
                                            error:error];
    }];
    clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
    [task resume];
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getUserInfoWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getUserInfoWithCompletionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getUserInfoWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    NSDictionary *userInfo = nil;
    @synchronized (self) {
        userInfo = self.userInfo;
    }
    if(userInfo){
        if(completion){
            completion(userInfo,nil);
        }
        return nil;
    }
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error)
     {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processDictionaryCompletion:completion
                                             withData:nil
                                             response:nil
                                                error:error];
        }
        else{
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:[endpointConfiguration.authZeroURL URLByAppendingPathComponent:kMCHUserInfo]
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                
                MCHAPIClientDictionaryCompletionBlock resultCompletion =
                ^(NSDictionary * _Nullable resultDictionary, NSError * _Nullable resultError) {
                    @synchronized (strongSelf) {
                        strongSelf.userInfo = resultDictionary;
                    }
                    if (completion) {
                        completion (resultDictionary, resultError);
                    }
                };
                [MCHAPIClient processDictionaryCompletion:resultCompletion
                                                 withData:data
                                                 response:response
                                                    error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getDevicesForUserWithID:(NSString *)userID
                                              completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getDevicesForUserWithID:userID
                                                       completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getDevicesForUserWithID:userID
                                                                        completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getDevicesForUserWithID:(NSString *)userID
                                               completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    NSParameterAssert(userID);
    if (userID == nil) {
        if (completion) {
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]);
        }
        return nil;
    }
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error){
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processDictionaryCompletion:completion
                                             withData:nil
                                             response:nil
                                                error:error];
        }
        else{
            NSURL *requestURL = [[[endpointConfiguration serviceDeviceURL] URLByAppendingPathComponent:kMCHDeviceV1User] URLByAppendingPathComponent:userID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processDictionaryCompletion:completion
                                                 withData:data
                                                 response:response
                                                    error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getDeviceInfoWithID:(NSString *)deviceID
                                          completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getDeviceInfoWithID:deviceID
                                                   completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getDeviceInfoWithID:deviceID
                                                                    completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getDeviceInfoWithID:(NSString *)deviceID
                                           completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    NSParameterAssert(deviceID);
    if (deviceID == nil) {
        if (completion) {
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]);
        }
        return nil;
    }
    NSParameterAssert(deviceID);
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error)
     {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processDictionaryCompletion:completion
                                             withData:nil
                                             response:nil
                                                error:error];
        }
        else{
            NSURL *requestURL = [[[endpointConfiguration serviceDeviceURL] URLByAppendingPathComponent:kMCHDeviceV1Device] URLByAppendingPathComponent:deviceID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processDictionaryCompletion:completion
                                                 withData:data
                                                 response:response
                                                    error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getFilesForDeviceWithURL:(NSURL *)proxyURL
                                                      parentID:(NSString *)parentID
                                               completionBlock:(MCHAPIClientArrayCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientArrayCompletionBlock resultCompletion = ^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(array,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getFilesForDeviceWithURL:proxyURL
                                                               parentID:parentID
                                                        completionBlock:^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getFilesForDeviceWithURL:proxyURL
                                                                                parentID:parentID
                                                                         completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(array,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getFilesForDeviceWithURL:(NSURL *)proxyURL
                                                       parentID:(NSString *)parentID
                                                completionBlock:(MCHAPIClientArrayCompletionBlock _Nullable)completion{
    NSParameterAssert(proxyURL);
    NSParameterAssert(parentID);
    if (proxyURL == nil || parentID == nil) {
        if (completion) {
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSMutableArray *resultFiles = [NSMutableArray new];
    return [self getFilesForDeviceWithURL:proxyURL
                                 parentID:parentID
                                pageToken:nil
                              resultFiles:resultFiles
                          completionBlock:completion];
}

- (id<MCHAPIClientCancellableRequest>)getFilesForDeviceWithURL:(NSURL *)proxyURL
                                                      parentID:(NSString *)parentID
                                                     pageToken:(NSString *_Nullable)pageToken
                                                   resultFiles:(NSMutableArray *)resultFiles
                                               completionBlock:(MCHAPIClientArrayCompletionBlock _Nullable)completion{
    NSParameterAssert(proxyURL);
    NSParameterAssert(parentID);
    if (proxyURL == nil || parentID == nil) {
        if (completion) {
            completion(nil,[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]);
        }
        return nil;
    }
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            if(completion){
                completion(nil,error);
            }
        }
        else{
            NSString *urlString = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",
                                   [proxyURL URLByAppendingPathComponent:kMCHSdkV2FilesSearchParents],
                                   kMCHIds,
                                   parentID,
                                   kMCHLimit,
                                   @(kMCHDefaultLimit)];
            if(pageToken.length>0){
                urlString = [urlString stringByAppendingFormat:@"&%@=%@",
                             kMCHPageToken,
                             pageToken];
            }
            NSURL *requestURL = [NSURL URLWithString:urlString];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [MCHAPIClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                    NSArray *responseArray = nil;
                    if([dictionary isKindOfClass:[NSDictionary class]] && [dictionary objectForKey:kMCHFiles]){
                        responseArray = [dictionary objectForKey:kMCHFiles];
                    }
                    if(responseArray.count>0){
                        [resultFiles addObjectsFromArray:responseArray];
                    }
                    NSString *pageToken = nil;
                    if([dictionary isKindOfClass:[NSDictionary class]] && [dictionary objectForKey:kMCHPageToken]){
                        pageToken = [dictionary objectForKey:kMCHPageToken];
                    }
                    if([pageToken isKindOfClass:[NSString class]] && pageToken.length>0){
                        id<MCHAPIClientCancellableRequest> nextPageRequest = [strongSelf getFilesForDeviceWithURL:proxyURL
                                                                                                         parentID:parentID
                                                                                                        pageToken:pageToken
                                                                                                      resultFiles:resultFiles
                                                                                                  completionBlock:completion];
                        weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)nextPageRequest;
                    }
                    else{
                        [strongSelf removeCancellableRequest:weak_clientRequest];
                        if(resultFiles.count==0 || error){
                            if(completion){
                                completion(nil,error);
                            }
                        }
                        else{
                            if(completion){
                                completion(resultFiles,nil);
                            }
                        }
                    }
                } withData:data response:response error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getFileInfoForDeviceWithURL:(NSURL *)proxyURL
                                                           fileID:(NSString *)fileID
                                                  completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getFileInfoForDeviceWithURL:proxyURL
                                                                    fileID:fileID
                                                           completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getFileInfoForDeviceWithURL:proxyURL
                                                                                     fileID:fileID
                                                                            completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getFileInfoForDeviceWithURL:(NSURL *)proxyURL
                                                            fileID:(NSString *)fileID
                                                   completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [MCHAPIClient processDictionaryCompletion:completion
                                         withData:nil
                                         response:nil
                                            error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processDictionaryCompletion:completion
                                             withData:nil
                                             response:nil
                                                error:error];
        }
        else{
            NSURL *requestURL = [[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processDictionaryCompletion:completion
                                                 withData:data
                                                 response:response
                                                    error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                 completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _deleteFileForDeviceWithURL:proxyURL
                                                                   fileID:fileID
                                                          completionBlock:^(NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _deleteFileForDeviceWithURL:proxyURL
                                                                                    fileID:fileID
                                                                           completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                           fileID:(NSString *)fileID
                                                  completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [MCHAPIClient processErrorCompletion:completion
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processErrorCompletion:completion
                                        response:nil
                                           error:error];
        }
        else{
            NSURL *requestURL = [[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID];
            NSMutableURLRequest *request = [strongSelf DELETERequestWithURL:requestURL
                                                                contentType:kMCHContentTypeApplicationJSON
                                                                accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processErrorCompletion:completion
                                            response:response
                                               error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                          parentID:(NSString *)parentID
                                                        folderName:(NSString *)folderName
                                                   completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    return [self createItemForDeviceWithURL:proxyURL
                                   parentID:parentID
                                   itemName:folderName
                               itemMIMEType:kMCHMIMETypeFolder
                            completionBlock:completion];
}

- (id<MCHAPIClientCancellableRequest>)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                        parentID:(NSString *)parentID
                                                        fileName:(NSString *)fileName
                                                    fileMIMEType:(NSString *)fileMIMEType
                                                 completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    return [self createItemForDeviceWithURL:proxyURL
                                   parentID:parentID
                                   itemName:fileName
                               itemMIMEType:fileMIMEType
                            completionBlock:completion];
}

- (id<MCHAPIClientCancellableRequest>)createItemForDeviceWithURL:(NSURL *)proxyURL
                                                        parentID:(NSString *)parentID
                                                        itemName:(NSString *)itemName
                                                    itemMIMEType:(NSString *)itemMIMEType
                                                 completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _createItemForDeviceWithURL:proxyURL
                                                                 parentID:parentID
                                                                 itemName:itemName
                                                             itemMIMEType:itemMIMEType
                                                          completionBlock:^(NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _createItemForDeviceWithURL:proxyURL
                                                                                  parentID:parentID
                                                                                  itemName:itemName
                                                                              itemMIMEType:itemMIMEType
                                                                           completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_createItemForDeviceWithURL:(NSURL *)proxyURL
                                                         parentID:(NSString *)parentID
                                                         itemName:(NSString *)itemName
                                                     itemMIMEType:(NSString *)itemMIMEType
                                                  completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(parentID);
    NSParameterAssert(itemName);
    NSParameterAssert(itemMIMEType);
    if(proxyURL==nil || parentID==nil || itemName==nil || itemMIMEType==nil){
        [MCHAPIClient processErrorCompletion:completion
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processErrorCompletion:completion
                                        response:nil
                                           error:error];
        }
        else{
            NSURL *requestURL = [proxyURL URLByAppendingPathComponent:kMCHSdkV2Files];
            NSString *boundary = [MCHAPIClient createMultipartFormBoundary];
            NSString *contentType = [NSString stringWithFormat:@"%@;boundary=%@",
                                     kMCHContentTypeMultipartRelated,
                                     boundary];
            NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                              contentType:contentType
                                                              accessToken:accessToken];
            NSDictionary *parameters = @{@"name":itemName,
                                         @"parentID":parentID};
            if(itemMIMEType.length>0){
                NSMutableDictionary *mparameters = [parameters mutableCopy];
                [mparameters setObject:itemMIMEType forKey:@"mimeType"];
                parameters = mparameters;
            }
            NSData *body = [MCHAPIClient createMultipartRelatedBodyWithBoundary:boundary
                                                                     parameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processErrorCompletion:completion
                                            response:response
                                               error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                     newFileName:(NSString *)newFileName
                                                 completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    NSDictionary *parameters = @{@"name":newFileName};
    return [self patchFileForDeviceWithURL:proxyURL
                                    fileID:fileID
                                parameters:parameters
                           completionBlock:completion];
}

- (id<MCHAPIClientCancellableRequest>)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                        fileID:(NSString *)fileID
                                                   newParentID:(NSString *)newParentID
                                               completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    NSDictionary *parameters = @{@"parentID":newParentID};
    return [self patchFileForDeviceWithURL:proxyURL
                                    fileID:fileID
                                parameters:parameters
                           completionBlock:completion];
}

- (id<MCHAPIClientCancellableRequest>)patchFileForDeviceWithURL:(NSURL *)proxyURL
                                                         fileID:(NSString *)fileID
                                                     parameters:(NSDictionary<NSString *,NSString *> *)parameters
                                                completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _patchFileForDeviceWithURL:proxyURL
                                                                  fileID:fileID
                                                              parameters:parameters
                                                         completionBlock:^(NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _patchFileForDeviceWithURL:proxyURL
                                                                                   fileID:fileID
                                                                               parameters:parameters
                                                                          completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_patchFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                      parameters:(NSDictionary<NSString *,NSString *> *)parameters
                                                 completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    NSParameterAssert(parameters);
    if(proxyURL==nil || fileID==nil || parameters==nil){
        [MCHAPIClient processErrorCompletion:completion
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processErrorCompletion:completion
                                        response:nil
                                           error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHPatch];
            NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                              contentType:kMCHContentTypeApplicationJSON
                                                              accessToken:accessToken];
            NSData *body = [MCHAPIClient createJSONBodyWithParameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [MCHAPIClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processErrorCompletion:completion
                                            response:response
                                               error:error];
            }];
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                              fileID:(NSString *)fileID
                                                          parameters:(NSDictionary *)additionalHeaders
                                                 didReceiveDataBlock:(MCHAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                             didReceiveResponseBlock:(MCHAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                     completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [MCHAPIClient processErrorCompletion:completion
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.didReceiveDataBlock = didReceiveData;
    clientRequest.didReceiveResponseBlock = didReceiveResponse;
    clientRequest.errorCompletionBlock = completion;
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processErrorCompletion:completion response:nil error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:nil
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            [additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [request setValue:obj forHTTPHeaderField:key];
            }];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request];
            weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [MCHAPIClient printRequest:request];
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                            fileID:(NSString *)fileID
                                                   completionBlock:(MCHAPIClientURLCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    MCHAPIClientURLCompletionBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(location,error);
        }
    };
    id<MCHAPIClientCancellableRequest> internalRequest =
    (id<MCHAPIClientCancellableRequest>)[self _getDirectURLForDeviceWithURL:proxyURL
                                                                     fileID:fileID
                                                            completionBlock:^(NSURL *_Nullable location, NSError * _Nullable error) {
        if (error.MCH_isTooManyRequestsError) {
            [MCHAPIClient dispatchAfterRetryTimeoutBlock:^{
                weak_clientRequest.internalRequest = [weakSelf _getDirectURLForDeviceWithURL:proxyURL
                                                                                      fileID:fileID
                                                                             completionBlock:resultCompletion];
            }];
        }
        else {
            resultCompletion(location,error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)_getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                             fileID:(NSString *)fileID
                                                    completionBlock:(MCHAPIClientURLCompletionBlock _Nullable)completion{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [MCHAPIClient processURLCompletion:completion
                                       url:nil
                                     error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processURLCompletion:completion
                                           url:nil
                                         error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSString *requestURLStringWithAuth = [NSString stringWithFormat:@"%@?access_token=%@",requestURL.absoluteString,accessToken];
            NSURL *requestURLWithAuth = [NSURL URLWithString:requestURLStringWithAuth];
            [MCHAPIClient processURLCompletion:completion
                                           url:requestURLWithAuth
                                         error:(requestURLWithAuth==nil)?[NSError MCHErrorWithCode:MCHErrorCodeCannotGetDirectURL]:nil];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                   fileID:(NSString *)fileID
                                                            progressBlock:(MCHAPIClientProgressBlock _Nullable)progressBlock
                                                          completionBlock:(MCHAPIClientURLCompletionBlock _Nullable)downloadCompletionBlock{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [MCHAPIClient processURLCompletion:downloadCompletionBlock
                                       url:nil
                                     error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.progressBlock = progressBlock;
    clientRequest.downloadCompletionBlock = downloadCompletionBlock;
    MCHMakeWeakReference(clientRequest);
    id<MCHAPIClientCancellableRequest> infoRequest = [self getFileInfoForDeviceWithURL:proxyURL
                                                                                fileID:fileID
                                                                       completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if(dictionary){
            MCHFile *file = [[MCHFile alloc] initWithDictionary:dictionary];
            weak_clientRequest.totalContentSize = file.size;
        }
        MCHMakeStrongSelfAndReturnIfNil;
        id<MCHAPIClientCancellableRequest> tokenRequest =
        [strongSelf getAccessTokenAndEndpointConfigurationWithCompletionBlock:
         ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
            MCHMakeStrongSelfAndReturnIfNil;
            if(error){
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHAPIClient processURLCompletion:downloadCompletionBlock
                                               url:nil
                                             error:error];
            }
            else{
                NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
                NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                                 contentType:nil
                                                                 accessToken:accessToken];
                [MCHAPIClient printRequest:request];
                NSURLSessionDownloadTask *task = [strongSelf downloadTaskWithRequest:request];
                weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
                weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
                [task resume];
            }
        }];
        clientRequest.internalRequest = tokenRequest;
    }];
    clientRequest.internalRequest = infoRequest;
    return clientRequest;
}

- (id<MCHAPIClientCancellableRequest>)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                           fileID:(NSString *)fileID
                                                                  localContentURL:(NSURL *)localContentURL
                                                                    progressBlock:(MCHAPIClientProgressBlock _Nullable)progressBlock
                                                                  completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completionBlock{
    MCHMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    NSParameterAssert(localContentURL);
    if(proxyURL==nil || fileID==nil || localContentURL==nil){
        [MCHAPIClient processErrorCompletion:completionBlock
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:localContentURL.path] == NO) {
        [MCHAPIClient processErrorCompletion:completionBlock
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeLocalFileNotFound]];
        return nil;
    }
    unsigned long long contentSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localContentURL.path error:nil] fileSize];
    if(contentSize==0 || contentSize==-1){
        [MCHAPIClient processErrorCompletion:completionBlock
                                    response:nil
                                       error:[NSError MCHErrorWithCode:MCHErrorCodeLocalFileEmpty]];
        return nil;
    }
    
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.progressBlock = progressBlock;
    clientRequest.errorCompletionBlock = completionBlock;
    clientRequest.totalContentSize = @(contentSize);
    MCHMakeWeakReference(clientRequest);
    
    id<MCHAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenAndEndpointConfigurationWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSString * _Nullable accessToken, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [MCHAPIClient processErrorCompletion:completionBlock
                                        response:nil
                                           error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSMutableURLRequest *request = [strongSelf PUTRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationXWWWFormURLEncoded
                                                             accessToken:accessToken];
            [MCHAPIClient printRequest:request];
            NSURLSessionUploadTask *task = [strongSelf uploadTaskWithRequest:request
                                                                    fromFile:localContentURL];
            weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(nullable NSError *)error{
    NSArray *tasks = [self allCancellableRequestsWithURLTasks];
    [tasks enumerateObjectsUsingBlock:^(MCHAPIClientRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.errorCompletionBlock){
            obj.errorCompletionBlock(error);
        }
        [self removeCancellableRequest:obj];
    }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToSend>0?totalBytesExpectedToSend:[request.totalContentSize longLongValue];
    if(request.progressBlock && totalSize>0){
        request.progressBlock((float)totalBytesSent/(float)totalSize);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    if(request.errorCompletionBlock){
        request.errorCompletionBlock(error);
    }
    if(request.downloadCompletionBlock){
        request.downloadCompletionBlock(nil,error);
    }
    [self removeCancellableRequest:request];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if(request.didReceiveResponseBlock){
        request.didReceiveResponseBlock(response);
    }
    if(completionHandler){
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if(request.didReceiveDataBlock){
        request.didReceiveDataBlock(data);
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    if(request.downloadCompletionBlock){
        request.downloadCompletionBlock(location,nil);
    }
    [self removeCancellableRequest:request];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    MCHAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToWrite>0?totalBytesExpectedToWrite:[request.totalContentSize longLongValue];
    if(request.progressBlock && totalSize>0){
        request.progressBlock((float)totalBytesWritten/(float)totalSize);
    }
}

#pragma mark - Private

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

- (id<MCHAPIClientCancellableRequest>)getAccessTokenAndEndpointConfigurationWithCompletionBlock:(MCHAPIClientEndpointAndAccessTokenCompletionBlock)completion{
    MCHMakeWeakSelf;
    MCHAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    MCHMakeWeakReference(clientRequest);
    void(^getAccessTokenForEndpointConfigurationBlock)(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, NSError * _Nullable endpointError) = ^(id<MCHEndpointConfiguration>_Nullable endpointConfiguration, NSError * _Nullable endpointError){
        MCHMakeStrongSelfAndReturnIfNil;
        MCHAppAuthProvider *authProvider = nil;
        @synchronized (strongSelf) {
            authProvider = strongSelf.authProvider;
        }
        NSCParameterAssert(authProvider);
        if(authProvider){
            [authProvider getAccessTokenWithCompletionBlock:^(NSString * _Nonnull accessToken, NSError * _Nonnull error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                if(completion){
                    completion(endpointConfiguration,accessToken,endpointError?:error);
                }
            }];
        }
        else{
            [strongSelf removeCancellableRequest:weak_clientRequest];
            if(completion){
                completion(endpointConfiguration,nil,[NSError MCHErrorWithCode:MCHErrorCodeAuthProviderIsNil]);
            }
        }
    };
    
    id<MCHEndpointConfiguration> configuration = nil;
    @synchronized (self) {
        configuration = self.endpointConfiguration;
    }
    
    if(configuration){
        getAccessTokenForEndpointConfigurationBlock(configuration,nil);
    }
    else{
        id<MCHAPIClientCancellableRequest> internalRequest =
        [self getEndpointConfigurationWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            MCHMakeStrongSelfAndReturnIfNil;
            id<MCHEndpointConfiguration> endpointConfiguration = nil;
            if(dictionary){
                endpointConfiguration =
                [MCHEndpointConfigurationBuilder configurationWithDictionary:dictionary];
                @synchronized (strongSelf) {
                    strongSelf.endpointConfiguration = endpointConfiguration;
                }
            }
            weak_clientRequest.internalRequest = nil;
            getAccessTokenForEndpointConfigurationBlock(endpointConfiguration,error);
        }];
        clientRequest.internalRequest = internalRequest;
    }
    return clientRequest;
}

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *)contentType
                                        accessToken:(NSString * _Nullable)accessToken{
    return [self requestWithURL:requestURL
                         method:@"GET"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           contentType:(NSString *)contentType
                                           accessToken:(NSString * _Nullable)accessToken{
    return [self requestWithURL:requestURL
                         method:@"DELETE"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(NSString * _Nullable)accessToken{
    return [self requestWithURL:requestURL
                         method:@"POST"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *)contentType
                                        accessToken:(NSString * _Nullable)accessToken{
    return [self requestWithURL:requestURL
                         method:@"PUT"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)requestWithURL:(NSURL *)requestURL
                                          method:(NSString *)method
                                     contentType:(NSString *)contentType
                                     accessToken:(NSString * _Nullable)accessToken{
    NSParameterAssert(requestURL);
    if(requestURL){
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
        [request setHTTPMethod:method];
        if(accessToken){
            [request addValue:[NSString stringWithFormat:@"Bearer %@",accessToken] forHTTPHeaderField:@"Authorization"];
        }
        if(contentType){
            [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
        return request;
    }
    return nil;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session dataTaskWithRequest:request completionHandler:completionHandler];
    }
    if(completionHandler){
        completionHandler(nil,nil,[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]);
    }
    return nil;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session dataTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session downloadTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session uploadTaskWithRequest:request fromFile:fileURL];
    }
    return nil;
}

+ (void)processDictionaryCompletion:(MCHAPIClientDictionaryCompletionBlock)completion
                           withData:(NSData * _Nullable)data
                           response:(NSURLResponse * _Nullable)response
                              error:(NSError * _Nullable)error{
    NSDictionary *responseDictionary = nil;
    NSError *parsingError = nil;
    if(data){
        responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];
    }
    NSError *objectValidationError = nil;
    if([responseDictionary isKindOfClass:[NSDictionary class]]==NO){
        responseDictionary = nil;
        objectValidationError = [NSError MCHErrorWithCode:MCHErrorCodeBadResponse];
    }
    NSError *resultError = nil;
    NSHTTPURLResponse *HTTPResponse = nil;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        HTTPResponse = (NSHTTPURLResponse *)response;
    }
    if([response isKindOfClass:[NSHTTPURLResponse class]] && ([HTTPResponse statusCode]>=300 || [HTTPResponse statusCode]<200)){
        resultError = [NSError errorWithDomain:NSURLErrorDomain code:[HTTPResponse statusCode] userInfo:nil];
    }
    else{
        if(error){
            resultError = error;
        }
        else if(parsingError){
            resultError = parsingError;
        }
        else{
            resultError = objectValidationError;
        }
    }
    if(completion){
        completion(responseDictionary,resultError);
    }
}

+ (NSError * _Nullable)processErrorCompletion:(MCHAPIClientErrorCompletionBlock)completion
                                     response:(NSURLResponse * _Nullable)response
                                        error:(NSError * _Nullable)error{
    NSHTTPURLResponse *HTTPResponse = nil;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        HTTPResponse = (NSHTTPURLResponse *)response;
    }
    NSError *resultError = nil;
    if(error){
        resultError = error;
    }
    else if([response isKindOfClass:[NSHTTPURLResponse class]] && ([HTTPResponse statusCode]>=300 || [HTTPResponse statusCode]<200)){
        resultError = [NSError errorWithDomain:NSURLErrorDomain code:[HTTPResponse statusCode] userInfo:nil];
    }
    if(completion){
        completion(resultError);
    }
    return resultError;
}

+ (NSURL * _Nullable)processURLCompletion:(MCHAPIClientURLCompletionBlock)completion
                                      url:(NSURL * _Nullable)url
                                    error:(NSError * _Nullable)error{
    if(completion){
        completion(url,error);
    }
    return url;
}

+ (NSData *)createMultipartRelatedBodyWithBoundary:(NSString *)boundary
                                        parameters:(NSDictionary<NSString *,NSString *> *)parameters {
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"{" dataUsingEncoding:NSUTF8StringEncoding]];
    __block NSUInteger index = 0;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        NSString *separator = (index<(parameters.count-1))?@",":@"";
        [httpBody appendData:[[NSString stringWithFormat:@"\"%@\":\"%@\"%@", parameterKey, parameterValue,separator] dataUsingEncoding:NSUTF8StringEncoding]];
        index++;
    }];
    [httpBody appendData:[@"}" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return httpBody;
}

+ (NSData *)createJSONBodyWithParameters:(NSDictionary<NSString *,NSString *> *)parameters {
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[@"{" dataUsingEncoding:NSUTF8StringEncoding]];
    __block NSUInteger index = 0;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        NSString *separator = (index<(parameters.count-1))?@",":@"";
        [httpBody appendData:[[NSString stringWithFormat:@"\"%@\":\"%@\"%@", parameterKey, parameterValue,separator] dataUsingEncoding:NSUTF8StringEncoding]];
        index++;
    }];
    [httpBody appendData:[@"}" dataUsingEncoding:NSUTF8StringEncoding]];
    return httpBody;
}

+ (NSString *)createMultipartFormBoundary{
    return [NSString stringWithFormat:@"foo%08X%08X", arc4random(), arc4random()];
}

+ (void)printRequest:(NSURLRequest *)request{
    NSLog(@"URL: %@\nHEADER_FIELDS:%@\nBODY: %@",request.URL.absoluteString,
          request.allHTTPHeaderFields,
          [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
}

+ (void)dispatchAfterRetryTimeoutBlock:(dispatch_block_t)block{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(kMCHAPIClientRequestRetryTimeout * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        if (block){
            block();
        }
    });
}

@end

@implementation MCHAPIClientRequest

- (instancetype)initWithInternalRequest:(id<MCHAPIClientCancellableRequest>)internalRequest{
    self = [super init];
    if(self){
        self.internalRequest = internalRequest;
    }
    return self;
}

- (void)cancel{
    @synchronized(self){
        _сancelled = YES;
        [self.internalRequest cancel];
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
