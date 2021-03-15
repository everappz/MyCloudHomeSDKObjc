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
    NSError *underlyingError = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:nil];
    return [NSError errorWithDomain:MCHErrorDomain code:errorCode
                           userInfo:@{NSUnderlyingErrorKey:underlyingError}];
}

- (BOOL)MCH_isTooManyRequestsError{
    return [self.domain isEqualToString:NSURLErrorDomain] && self.code == 429;
}

- (BOOL)MCH_isAuthError{
    const BOOL isCannotGetAccessTokenError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeCannotGetAccessToken;
    const BOOL isAccessTokenExpiredError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeAccessTokenExpired;
    const BOOL isCannotUpdateAccessTokenError = [self.domain isEqualToString:MCHErrorDomain] && self.code == MCHErrorCodeCannotUpdateAccessToken;
    const BOOL isUnauthorizedError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 401;
    const BOOL isForbiddenError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 403;

    NSError *underlyingError = [self.userInfo objectForKey:NSUnderlyingErrorKey];
    
    const BOOL isUnderlyingErrorUnauthorized = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 401;
    const BOOL isUnderlyingErrorForbidden = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 403;
    
    return isCannotGetAccessTokenError ||
    isAccessTokenExpiredError ||
    isCannotUpdateAccessTokenError ||
    isUnauthorizedError ||
    isForbiddenError ||
    isUnderlyingErrorUnauthorized ||
    isUnderlyingErrorForbidden;
}

@end
