//
//  MCHAccessToken.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import "MCHAccessToken.h"

@interface MCHAccessToken ()

@property (nonatomic,copy)NSString *token;

@property (nonatomic,copy)NSString *type;

@end


@implementation MCHAccessToken

+ (instancetype)accessTokenWithToken:(NSString *)token type:(NSString *)type{
    NSParameterAssert(token);
    NSParameterAssert(type);
    if(token == nil){
        return nil;
    }
    if(type == nil){
        return nil;
    }
    MCHAccessToken *accessToken = [MCHAccessToken new];
    accessToken.token = token;
    accessToken.type = type;
    return accessToken;
}

@end
