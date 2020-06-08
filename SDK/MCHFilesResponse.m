//
//  MCHFilesResponse.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHFilesResponse.h"

@implementation MCHFilesResponse

- (NSArray<NSDictionary *> *)files{
    return [self.class arrayForKey:@"files" inDictionary:self.dictionary];
}

@end
