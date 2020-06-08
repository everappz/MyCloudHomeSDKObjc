//
//  MCHFile.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHFile.h"

@implementation MCHFile

- (NSString *)identifier{
    return [self.class stringForKey:@"id" inDictionary:self.dictionary];
}

- (NSString *)parentID{
    return [self.class stringForKey:@"parentID" inDictionary:self.dictionary];
}

- (NSString *)eTag{
    return [self.class stringForKey:@"eTag" inDictionary:self.dictionary];
}

- (NSNumber *)childCount{
    return [self.class numberForKey:@"childCount" inDictionary:self.dictionary];
}

- (NSNumber *)size{
    return [self.class numberForKey:@"size" inDictionary:self.dictionary];
}

- (NSString *)extension{
    return [self.class stringForKey:@"extension" inDictionary:self.dictionary];
}

- (NSString *)mimeType{
    return [self.class stringForKey:@"mimeType" inDictionary:self.dictionary];
}

- (NSString *)name{
    return [self.class stringForKey:@"name" inDictionary:self.dictionary];
}

- (NSString *)storageType{
    return [self.class stringForKey:@"storageType" inDictionary:self.dictionary];
}

- (NSString *)hidden{
    return [self.class stringForKey:@"hidden" inDictionary:self.dictionary];
}

- (NSDate *)mTime{
    return [self.class dateForKey:@"mTime" inDictionary:self.dictionary];
}

- (NSDate *)cTime{
    return [self.class dateForKey:@"cTime" inDictionary:self.dictionary];
}

@end



