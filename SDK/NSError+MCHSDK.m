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

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode {
    return [NSError errorWithDomain:MCHErrorDomain
                               code:errorCode
                           userInfo:nil];
}

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode
                      statusCode:(NSInteger)statusCode
{
    NSError *underlyingError = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:nil];
    return [NSError errorWithDomain:MCHErrorDomain code:errorCode
                           userInfo:@{NSUnderlyingErrorKey:underlyingError}];
}

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode
                 underlyingError:(NSError *)underlyingError
{
    return [NSError errorWithDomain:MCHErrorDomain
                               code:errorCode
                           userInfo:underlyingError!=nil?@{NSUnderlyingErrorKey:underlyingError}:nil];
}

- (BOOL)MCH_isTooManyRequestsError{
    return [self.domain isEqualToString:NSURLErrorDomain] && self.code == 429;
}

- (BOOL)MCH_isAuthError{
    const BOOL isCannotGetAccessTokenError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeCannotGetAccessToken;
    if (isCannotGetAccessTokenError) {
        return YES;
    }
    
    const BOOL isAccessTokenExpiredError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeAccessTokenExpired;
    if (isAccessTokenExpiredError) {
        return YES;
    }
    
    const BOOL isCannotUpdateAccessTokenError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeCannotUpdateAccessToken;
    if (isCannotUpdateAccessTokenError) {
        return YES;
    }
    
    const BOOL isUnauthorizedError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 401;
    if (isUnauthorizedError) {
        return YES;
    }
    
    const BOOL isForbiddenError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 403;
    if (isForbiddenError) {
        return YES;
    }
    
    NSError *underlyingError = [self.userInfo objectForKey:NSUnderlyingErrorKey];
    
    const BOOL isUnderlyingErrorUnauthorized = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 401;
    if (isUnderlyingErrorUnauthorized) {
        return YES;
    }
    
    const BOOL isUnderlyingErrorForbidden = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 403;
    if (isUnderlyingErrorForbidden) {
        return YES;
    }
    
    return NO;
}

@end
