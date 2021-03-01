//
//  MCHUser.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHUser.h"

NSString * const MCHUserApiKeyIdentifier = @"sub";
NSString * const MCHUserApiKeyEmail = @"email";

@implementation MCHUser

- (NSString *_Nullable)identifier{
    return [self.class stringForKey:MCHUserApiKeyIdentifier
                       inDictionary:self.dictionary];
}

- (NSString *_Nullable)email{
    return [self.class stringForKey:MCHUserApiKeyEmail
                       inDictionary:self.dictionary];
}

@end
