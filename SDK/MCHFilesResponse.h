//
//  MCHFilesResponse.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCHFilesResponse : MCHObject

- (NSArray<NSDictionary *> * _Nullable)files;

@end

NS_ASSUME_NONNULL_END
