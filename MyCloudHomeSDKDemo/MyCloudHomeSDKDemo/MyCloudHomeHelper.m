//
//  MyCloudHomeHelper.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "MyCloudHomeHelper.h"
#import "LSOnlineFile.h"
#import <MyCloudHomeSDKObjc/MCHAppAuthManager.h>
#import <MyCloudHomeSDKObjc/MCHAPIClient.h>
#import <MyCloudHomeSDKObjc/MCHAppAuthProvider.h>
#import <MyCloudHomeSDKObjc/MCHConstants.h>
#import <MyCloudHomeSDKObjc/MCHUser.h>
#import <MyCloudHomeSDKObjc/MCHDevice.h>
#import <MyCloudHomeSDKObjc/MCHFile.h>
#import <MyCloudHomeSDKObjc/MCHAPIClientCache.h>

unsigned long long LSFileContentLengthUnknown = -1;

NSString * const MCHAuthDataKey = @"MCHAuthDataKey";
NSString * const MCHUserID = @"MCHUserID";
NSString * const MCHUserEmail = @"MCHUserEmail";

@implementation MyCloudHomeHelper

+ (LSOnlineFile *)onlineFileForApiItem:(id)item
                       parentDirectory:(LSOnlineFile *)parentDirectory{
    NSString *rootPath = parentDirectory.url.path;
    NSParameterAssert(item);
    NSParameterAssert(rootPath);
    if(item && rootPath){
        if([item isKindOfClass:[MCHFile class]]){
            MCHFile *apiFile = (MCHFile *)item;
            NSString *title = [apiFile name];
            BOOL isDirectory = [apiFile.mimeType isEqualToString:kMCHMIMETypeFolder];
            title = [title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            unsigned long long size = apiFile.size?apiFile.size.unsignedIntegerValue:LSFileContentLengthUnknown;
            NSURL *url = [NSURL fileURLWithPath:[rootPath stringByAppendingPathComponent:title]];
            LSOnlineFile *file = [[LSOnlineFile alloc] init];
            file.url = url;
            file.contentLength = size;
            file.createdAt = apiFile.cTime;
            file.updatedAt = apiFile.mTime;
            file.directory = isDirectory;
            file.readOnly = NO;
            file.name = title;
            file.shared = NO;
            file.modelID = apiFile.identifier;
            file.modelTag = apiFile.eTag;
            file.deviceID = parentDirectory.deviceID;
            file.deviceURL = parentDirectory.deviceURL;
            return file;
        }
        else if([item isKindOfClass:[MCHDevice class]]){
            MCHDevice *device = (MCHDevice *)item;
            NSString *title = device.name;
            NSURL *url = [NSURL fileURLWithPath:[rootPath stringByAppendingPathComponent:title]];
            LSOnlineFile *file = [[LSOnlineFile alloc] init];
            file.url = url;
            file.directory = YES;
            file.readOnly = NO;
            file.name = title;
            file.shared = NO;
            file.modelID = device.deviceId;
            file.deviceID = device.deviceId;
            file.deviceURL = device.proxyURL;
            return file;
        }
        else if([item isKindOfClass:[LSOnlineFile class]]){
            return item;
        }
    }
    NSParameterAssert(NO);
    return nil;
}

+ (BOOL)shouldFilterApiFile:(id)file {
    return NO;
}

+ (NSArray<LSOnlineFile *> *)onlineFilesFromApiFiles:(id<NSFastEnumeration>)items
                                     parentDirectory:(LSOnlineFile *)parentDirectory{
    NSMutableArray<LSOnlineFile *> *resultFiles = [[NSMutableArray<LSOnlineFile *> alloc] init];
    if(items){
        for (id item in items) {
            if([self shouldFilterApiFile:item]){
                continue;
            }
            LSOnlineFile *onlineFile = nil;
            if([item isKindOfClass:[LSOnlineFile class]]==NO){
                onlineFile = [self onlineFileForApiItem:item
                                        parentDirectory:parentDirectory];
            }
            else{
                onlineFile = (LSOnlineFile *)item;
            }
            if(onlineFile){
                [resultFiles addObject:onlineFile];
            }
        }
    }
    return resultFiles;
}

+ (NSString *)uuidString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidStr;
}

+ (NSError *)unknownError{
    return [[NSError alloc] initWithDomain:@"MyCloudHomeErrorDomain" code:-1 userInfo:nil];
}

+ (MCHAPIClient *)createClientWithAuthData:(NSDictionary *)clientAuthData{
    MCHAPIClient *apiClient = nil;
    id authDataObj = [clientAuthData objectForKey:MCHAuthDataKey];
    NSString *userID = [clientAuthData objectForKey:MCHUserID];
    if([authDataObj isKindOfClass:[NSData class]]
       && userID.length > 0){
        NSData *authData = (NSData *)authDataObj;
        NSParameterAssert(authData.length>0);
        if(authData.length>0){
            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:authData];
            NSParameterAssert([obj isKindOfClass:[OIDAuthState class]]);
            if([obj isKindOfClass:[OIDAuthState class]]){
                OIDAuthState *authState = (OIDAuthState *)obj;
                apiClient = [[MCHAPIClientCache sharedCache] clientForIdentifier:userID];
                if (apiClient == nil) {
                    apiClient = [[MCHAPIClientCache sharedCache] createClientForIdentifier:userID
                                                                                  userInfo:nil
                                                                                 authState:authState];
                }
            }
        }
    }
    else{
        NSParameterAssert(NO);
    }
    NSParameterAssert(apiClient);
    return apiClient;
}

+ (NSString *)readableStringForByteSize:(NSNumber *)size{
    NSString * result_str = nil;
    long long fileSize = [size longLongValue];
    result_str = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
    return result_str;
}

@end
