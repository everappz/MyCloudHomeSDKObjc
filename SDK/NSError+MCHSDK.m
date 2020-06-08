//
//  NSError+MCHSDK.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "NSError+MCHSDK.h"

NSString * const MCHErrorDomain = @"MCHErrorDomain";

@implementation NSError(MCHSDK)

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode{
    return [NSError errorWithDomain:MCHErrorDomain
                               code:errorCode
                           userInfo:nil];
}

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode
                      statusCode:(NSInteger)statusCode{
    return [NSError errorWithDomain:MCHErrorDomain code:errorCode
                           userInfo:@{NSUnderlyingErrorKey:[NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:nil]}];
}

@end
