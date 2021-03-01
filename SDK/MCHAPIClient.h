//
//  MCHAPIClient.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MCHEndpointConfiguration;
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

@property (nonatomic,strong,readonly)id<MCHAPIClientCancellableRequest> internalRequest;

- (BOOL)isCancelled;

@end



@interface MCHAPIClient : NSObject

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                          endpointConfiguration:(id<MCHEndpointConfiguration> _Nullable)endpointConfiguration
                                   authProvider:(MCHAppAuthProvider *_Nullable)authProvider;

- (void)updateAuthProvider:(MCHAppAuthProvider * _Nullable)authProvider;

- (id<MCHAPIClientCancellableRequest> _Nullable)getEndpointConfigurationWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDevicesForUserWithID:(NSString *)userID
                                                        completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDeviceInfoWithID:(NSString *)deviceID
                                                    completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFilesForDeviceWithURL:(NSURL *)proxyURL
                                                                parentID:(NSString *)parentID
                                                         completionBlock:(MCHAPIClientArrayCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFileInfoForDeviceWithURL:(NSURL *)proxyURL
                                                                     fileID:(NSString *)fileID
                                                            completionBlock:(MCHAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                           completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                                    parentID:(NSString *)parentID
                                                                  folderName:(NSString *)folderName
                                                             completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  parentID:(NSString *)parentID
                                                                  fileName:(NSString *)fileName
                                                              fileMIMEType:(NSString *)fileMIMEType
                                                           completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                               newFileName:(NSString *)newFileName
                                                           completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  fileID:(NSString *)fileID
                                                             newParentID:(NSString *)newParentID
                                                         completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                        fileID:(NSString *)fileID
                                                                    parameters:(NSDictionary *_Nullable)additionalHeaders
                                                           didReceiveDataBlock:(MCHAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                       didReceiveResponseBlock:(MCHAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                               completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                             fileID:(NSString *)fileID
                                                                      progressBlock:(MCHAPIClientProgressBlock _Nullable)progressBlock
                                                                    completionBlock:(MCHAPIClientURLCompletionBlock _Nullable)downloadCompletionBlock;

- (id<MCHAPIClientCancellableRequest> _Nullable)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                                      fileID:(NSString *)fileID
                                                             completionBlock:(MCHAPIClientURLCompletionBlock _Nullable)completion;

- (id<MCHAPIClientCancellableRequest> _Nullable)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                                     fileID:(NSString *)fileID
                                                                            localContentURL:(NSURL *)localContentURL
                                                                              progressBlock:(MCHAPIClientProgressBlock _Nullable)progressBlock
                                                                            completionBlock:(MCHAPIClientErrorCompletionBlock _Nullable)completionBlock;

@end

NS_ASSUME_NONNULL_END
