//
//  MCHUser.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHUser.h"

@implementation MCHUser

- (NSString *)identifier{
    return [self.class stringForKey:@"sub" inDictionary:self.dictionary];
}

- (NSString *)email{
    return [self.class stringForKey:@"email" inDictionary:self.dictionary];
}

@end
