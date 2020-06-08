//
//  MCHFile.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCHFile : MCHObject

- (NSString * _Nullable)identifier;

- (NSString * _Nullable)parentID;

- (NSString * _Nullable)eTag;

- (NSNumber * _Nullable)childCount;

- (NSNumber * _Nullable)size;

- (NSString * _Nullable)extension;

- (NSString * _Nullable)mimeType;

- (NSString * _Nullable)name;

- (NSString * _Nullable)storageType;

- (NSString * _Nullable)hidden;

- (NSDate * _Nullable)mTime;

- (NSDate * _Nullable)cTime;

@end

NS_ASSUME_NONNULL_END
