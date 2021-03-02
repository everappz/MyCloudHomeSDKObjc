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
#import "MCHNetworkClient.h"
#import "MCHAPIClientRequest.h"
#import "MCHRequestsCache.h"

NSTimeInterval const kMCHAPIClientRequestRetryTimeout = 1.5;

@interface MCHAPIClient()

@property (nonatomic,strong)MCHNetworkClient *networkClient;
@property (nonatomic,strong,nullable)id<MCHEndpointConfiguration> endpointConfiguration;
@property (nonatomic,strong,nullable)MCHAppAuthProvider *authProvider;
@property (nonatomic,strong,nullable)NSDictionary *userInfo;

@end


@implementation MCHAPIClient


- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                          endpointConfiguration:(id<MCHEndpointConfiguration> _Nullable)endpointConfiguration
                                   authProvider:(MCHAppAuthProvider *_Nullable)authProvider{
    
    self = [super init];
    if(self){
        self.endpointConfiguration = endpointConfiguration;
        self.authProvider = authProvider;
        self.userInfo = nil;
        self.networkClient = [[MCHNetworkClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration];
    }
    return self;
}

- (void)updateAuthProvider:(MCHAppAuthProvider *_Nullable)authProvider{
    @synchronized (self) {
        self.authProvider = authProvider;
    }
}

#pragma mark - Public

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
    [MCHNetworkClient printRequest:request];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                         completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        MCHMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        [MCHNetworkClient processDictionaryCompletion:completion
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
            [MCHNetworkClient processDictionaryCompletion:completion
                                                 withData:nil
                                                 response:nil
                                                    error:error];
        }
        else{
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:[endpointConfiguration.authZeroURL URLByAppendingPathComponent:kMCHUserInfo]
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
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
                [MCHNetworkClient processDictionaryCompletion:resultCompletion
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
            [MCHNetworkClient processDictionaryCompletion:completion
                                                 withData:nil
                                                 response:nil
                                                    error:error];
        }
        else{
            NSURL *requestURL = [[[endpointConfiguration serviceDeviceURL] URLByAppendingPathComponent:kMCHDeviceV1User] URLByAppendingPathComponent:userID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processDictionaryCompletion:completion
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
            [MCHNetworkClient processDictionaryCompletion:completion
                                                 withData:nil
                                                 response:nil
                                                    error:error];
        }
        else{
            NSURL *requestURL = [[[endpointConfiguration serviceDeviceURL] URLByAppendingPathComponent:kMCHDeviceV1Device] URLByAppendingPathComponent:deviceID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processDictionaryCompletion:completion
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
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [MCHNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
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
        [MCHNetworkClient processDictionaryCompletion:completion
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
            [MCHNetworkClient processDictionaryCompletion:completion
                                                 withData:nil
                                                 response:nil
                                                    error:error];
        }
        else{
            NSURL *requestURL = [[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationJSON
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processDictionaryCompletion:completion
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
        [MCHNetworkClient processErrorCompletion:completion
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
            [MCHNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID];
            NSMutableURLRequest *request = [strongSelf DELETERequestWithURL:requestURL
                                                                contentType:kMCHContentTypeApplicationJSON
                                                                accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processErrorCompletion:completion
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
        [MCHNetworkClient processErrorCompletion:completion
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
            [MCHNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [proxyURL URLByAppendingPathComponent:kMCHSdkV2Files];
            NSString *boundary = [MCHNetworkClient createMultipartFormBoundary];
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
            NSData *body = [MCHNetworkClient createMultipartRelatedBodyWithBoundary:boundary
                                                                         parameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processErrorCompletion:completion
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
        [MCHNetworkClient processErrorCompletion:completion
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
            [MCHNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHPatch];
            NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                              contentType:kMCHContentTypeApplicationJSON
                                                              accessToken:accessToken];
            NSData *body = [MCHNetworkClient createJSONBodyWithParameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [MCHNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [MCHNetworkClient processErrorCompletion:completion
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
        [MCHNetworkClient processErrorCompletion:completion
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
            [MCHNetworkClient processErrorCompletion:completion response:nil error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:nil
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
            [additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [request setValue:obj forHTTPHeaderField:key];
            }];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request];
            weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
            weak_clientRequest.internalRequest = (id<MCHAPIClientCancellableRequest>)task;
            [MCHNetworkClient printRequest:request];
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
        [MCHNetworkClient processURLCompletion:completion
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
            [MCHNetworkClient processURLCompletion:completion
                                               url:nil
                                             error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSString *requestURLStringWithAuth = [NSString stringWithFormat:@"%@?access_token=%@",requestURL.absoluteString,accessToken];
            NSURL *requestURLWithAuth = [NSURL URLWithString:requestURLStringWithAuth];
            [MCHNetworkClient processURLCompletion:completion
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
        [MCHNetworkClient processURLCompletion:downloadCompletionBlock
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
                [MCHNetworkClient processURLCompletion:downloadCompletionBlock
                                                   url:nil
                                                 error:error];
            }
            else{
                NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
                NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                                 contentType:nil
                                                                 accessToken:accessToken];
                [MCHNetworkClient printRequest:request];
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
        [MCHNetworkClient processErrorCompletion:completionBlock
                                        response:nil
                                           error:[NSError MCHErrorWithCode:MCHErrorCodeBadInputParameters]];
        return nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:localContentURL.path] == NO) {
        [MCHNetworkClient processErrorCompletion:completionBlock
                                        response:nil
                                           error:[NSError MCHErrorWithCode:MCHErrorCodeLocalFileNotFound]];
        return nil;
    }
    unsigned long long contentSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localContentURL.path error:nil] fileSize];
    if(contentSize==0 || contentSize==-1){
        [MCHNetworkClient processErrorCompletion:completionBlock
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
            [MCHNetworkClient processErrorCompletion:completionBlock
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kMCHSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kMCHContent];
            NSMutableURLRequest *request = [strongSelf PUTRequestWithURL:requestURL
                                                             contentType:kMCHContentTypeApplicationXWWWFormURLEncoded
                                                             accessToken:accessToken];
            [MCHNetworkClient printRequest:request];
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

#pragma mark - Network

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *)contentType
                                        accessToken:(NSString * _Nullable)accessToken{
    return [self.networkClient GETRequestWithURL:requestURL
                                     contentType:contentType
                                     accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           contentType:(NSString *)contentType
                                           accessToken:(NSString * _Nullable)accessToken{
    return [self.networkClient DELETERequestWithURL:requestURL
                                        contentType:contentType
                                        accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(NSString * _Nullable)accessToken{
    return [self.networkClient POSTRequestWithURL:requestURL
                                      contentType:contentType
                                      accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *)contentType
                                        accessToken:(NSString * _Nullable)accessToken{
    return [self.networkClient PUTRequestWithURL:requestURL
                                     contentType:contentType
                                     accessToken:accessToken];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    return [self.networkClient dataTaskWithRequest:request
                                 completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient dataTaskWithRequest:request];
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient downloadTaskWithRequest:request];
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL{
    return [self.networkClient uploadTaskWithRequest:request
                                            fromFile:fileURL];
}

#pragma mark - Requests Cache

- (MCHAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    return [self.networkClient.requestsCache cancellableRequestWithURLTaskIdentifier:URLTaskIdentifier];
}

- (NSArray<MCHAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    return [self.networkClient.requestsCache allCancellableRequestsWithURLTasks];
}

- (MCHAPIClientRequest *)createAndAddCancellableRequest{
    return [self.networkClient.requestsCache createAndAddCancellableRequest];
}

- (void)addCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache addCancellableRequest:request];
}

- (void)removeCancellableRequest:(id<MCHAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache removeCancellableRequest:request];
}

#pragma mark - Internal

+ (void)dispatchAfterRetryTimeoutBlock:(dispatch_block_t)block{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(kMCHAPIClientRequestRetryTimeout * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        if (block){
            block();
        }
    });
}

@end

