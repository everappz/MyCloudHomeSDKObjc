//
//  MCHObject.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCHObject : NSObject

- (instancetype)initWithDictionary:(NSDictionary *_Nonnull)dictionary;

@property (nonatomic,strong,readonly)NSDictionary *dictionary;

+ (NSURL * _Nullable)HTTPURLForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

+ (NSString * _Nullable)stringForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

+ (NSDictionary * _Nullable)dictionaryForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

+ (NSNumber * _Nullable)numberForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

+ (NSArray<NSDictionary *> * _Nullable)arrayForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

+ (NSDate * _Nullable)dateForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
