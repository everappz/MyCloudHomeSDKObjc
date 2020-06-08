//
//  MyCloudHomeHelper.h
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LSOnlineFile;
@class MCHAPIClient;

#define LS_WEB_VIEW_SCALE_TO_FIT_SCRIPT() @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"

extern unsigned long long LSFileContentLengthUnknown;

extern NSString * const MCHAuthDataKey;
extern NSString * const MCHUserID;
extern NSString * const MCHClientID;

@interface MyCloudHomeHelper : NSObject

+ (LSOnlineFile *)onlineFileForApiItem:(id)item
                       parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSArray<LSOnlineFile *> *)onlineFilesFromApiFiles:(id<NSFastEnumeration>)items
                                     parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSString *)uuidString;

+ (NSError *)unknownError;

+ (MCHAPIClient *)createClientWithAuthData:(NSDictionary *)authData;

+ (NSString *)readableStringForByteSize:(NSNumber *)size;

@end

NS_ASSUME_NONNULL_END
