//
//  MCHAccessToken.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCHAccessToken : NSObject

@property (nonatomic, copy, readonly) NSString *token;

@property (nonatomic, copy, readonly) NSString *type;

+ (instancetype)accessTokenWithToken:(NSString *)token type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
