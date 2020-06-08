//
//  LSOnlineFile.h
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LSOnlineFile : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, assign) BOOL directory;
@property (nonatomic, assign) BOOL readOnly;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL shared;
@property (nonatomic, copy) NSString *modelID;
@property (nonatomic, copy) NSString *modelTag;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, strong) NSURL *deviceURL;

@end

NS_ASSUME_NONNULL_END
