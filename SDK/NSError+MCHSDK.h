//
//  NSError+MCHSDK.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, MCHErrorCode) {
    MCHErrorCodeCancelled = -999,
    MCHErrorCodeNone = 0,
    MCHErrorCodeCannotGetAuthURL,
    MCHErrorCodeCannotGetAccessToken,
    MCHErrorCodeAccessTokenExpired,
    MCHErrorCodeCannotUpdateAccessToken,
    MCHErrorCodeCannotGetEndpointConfiguration,
    MCHErrorCodeAuthProviderIsNil,
    MCHErrorCodeBadInputParameters,
    MCHErrorCodeBadResponse,
    MCHErrorCodeCannotGetDirectURL,
    MCHErrorCodeLocalFileNotFound,
    MCHErrorCodeLocalFileEmpty,
    MCHErrorCodeSafariOpenError,
    MCHErrorCodeCanceledAuthorizationFlow,
};

extern  NSString * const MCHErrorDomain;

@interface NSError (MCHSDK)

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode;

+ (instancetype)MCHErrorWithCode:(MCHErrorCode)errorCode statusCode:(NSInteger)statusCode;

- (BOOL)MCH_isTooManyRequestsError;

- (BOOL)MCH_isAuthError;

@end

NS_ASSUME_NONNULL_END

