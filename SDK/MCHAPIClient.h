//
//  MCHAPIClient.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MCHEndpointConfiguration;
@class MCHAppAuthProvider;

typedef void(^MCHAPIClientDictionaryCompletionBlock)(NSDictionary *_Nullable dictionary, NSError * _Nullable error);
typedef void(^MCHAPIClientArrayCompletionBlock)(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error);
typedef void(^MCHAPIClientVoidCompletionBlock)(void);
typedef void(^MCHAPIClientErrorCompletionBlock)(NSError * _Nullable error);
typedef void(^MCHAPIClientDidReceiveDataBlock)(NSData * _Nullable data);
typedef void(^MCHAPIClientDidReceiveResponseBlock)(NSURLResponse * _Nullable response);
typedef void(^MCHAPIClientProgressBlock)(float progress);
typedef void(^MCHAPIClientURLCompletionBlock)(NSURL *_Nullable location, NSError * _Nullable error);

@protocol MCHAPIClientCancellableRequest <NSObject>

- (void)cancel;

@end



@interface MCHAPIClientRequest : NSObject <MCHAPIClientCancellableRequest>

- (instancetype)initWithInternalRequest:(id<MCHAPIClientCancellableRequest>)internalRequest;

@property (nonatomic,strong, readonly)id<MCHAPIClientCancellableRequest> internalRequest;

- (BOOL)isCancelled;

@end



@interface MCHAPIClient : NSObject

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration * _Nullable )configuration
                       endpointConfiguration:(MCHEndpointConfiguration * _Nullable)endpointConfiguration
                                authProvider:(MCHAppAuthProvider *_Nullable)authProvider;

@property (nonatomic,strong)MCHAppAuthProvider *authProvider;

- (id<MCHAPIClientCancellableRequest> _Nullable)getEndpointConfigurationWithCompletion:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletion:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDevicesForUserWithID:(NSString * _Nonnull)userID
                                                         withCompletion:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDeviceInfoWithID:(NSString * _Nonnull)deviceID
                                                     withCompletion:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFilesForDeviceWithURL:(NSURL * _Nonnull)proxyURL
                                                                parentID:(NSString * _Nonnull)parentID
                                                          withCompletion:(MCHAPIClientArrayCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFileInfoForDeviceWithURL:(NSURL *)proxyURL
                                                                     fileID:(NSString *)fileID
                                                             withCompletion:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                            withCompletion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                                    parentID:(NSString *)parentID
                                                                  folderName:(NSString *)folderName
                                                              withCompletion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  parentID:(NSString *)parentID
                                                                  fileName:(NSString *)fileName
                                                              fileMIMEType:(NSString *)fileMIMEType
                                                            withCompletion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                               newFileName:(NSString *)newFileName
                                                            withCompletion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  fileID:(NSString *)fileID
                                                             newParentID:(NSString *)newParentID
                                                          withCompletion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                        fileID:(NSString *)fileID
                                                                    parameters:(NSDictionary *)additionalHeaders
                                                                didReceiveData:(MCHAPIClientDidReceiveDataBlock)didReceiveData
                                                            didReceiveResponse:(MCHAPIClientDidReceiveResponseBlock)didReceiveResponse
                                                                    completion:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                             fileID:(NSString *)fileID
                                                                      progressBlock:(MCHAPIClientProgressBlock)progressBlock
                                                                    completionBlock:(MCHAPIClientURLCompletionBlock)downloadCompletionBlock;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                                      fileID:(NSString *)fileID
                                                                  completion:(MCHAPIClientURLCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                                     fileID:(NSString *)fileID
                                                                            localContentURL:(NSURL *)localContentURL
                                                                              progressBlock:(MCHAPIClientProgressBlock)progressBlock
                                                                            completionBlock:(MCHAPIClientErrorCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
