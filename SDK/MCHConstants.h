//
//  MCHConstants.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MCHMakeWeakReferenceWithName(reference, weakReferenceName) __weak __typeof(reference) weakReferenceName = reference;
#define MCHMakeStrongReferenceWithName(reference, strongReferenceName) __strong __typeof(reference) strongReferenceName = reference;

#define MCHMakeWeakReference(reference) MCHMakeWeakReferenceWithName(reference, weak_##reference)
#define MCHMakeStrongReference(reference) MCHMakeStrongReferenceWithName(reference, strong_##reference)

#define MCHMakeStrongReferenceWithNameAndReturnValueIfNil(reference, strongReferenceName, value) \
MCHMakeStrongReferenceWithName(reference, strongReferenceName); \
if (nil == strongReferenceName) { \
return (value); \
} \

#define MCHMakeStrongReferenceWithNameAndReturnIfNil(reference, strongReferenceName) MCHMakeStrongReferenceWithNameAndReturnValueIfNil(reference, strongReferenceName, (void)0)

#define MCHMakeWeakSelf MCHMakeWeakReferenceWithName(self, weakSelf);
#define MCHMakeStrongSelf MCHMakeWeakReferenceWithName(weakSelf, strongSelf);

#define MCHMakeStrongSelfAndReturnIfNil MCHMakeStrongReferenceWithNameAndReturnIfNil(weakSelf,strongSelf);

extern NSString * const kMCHClientConfigURL;
extern NSString * const kMCHComponentMap;
extern NSString * const kMCHCloudServiceUrls;
extern NSString * const kMCHServiceDeviceUrl;
extern NSString * const kMCHServiceDevicenetworkUrl;
extern NSString * const kMCHServiceAuth0Url;
extern NSString * const kMCHServiceAuthUrl;
extern NSString * const kMCHData;
extern NSString * const kMCHFiles;
extern NSString * const kMCHContent;
extern NSString * const kMCHPatch;
extern NSString * const kMCHAuthorize;
extern NSString * const kMCHOAuthToken;
extern NSString * const kMCHUserInfo;
extern NSString * const kMCHDeviceV1User;
extern NSString * const kMCHDeviceV1Device;
extern NSString * const kMCHSdkV2Files;
extern NSString * const kMCHSdkV2FilesSearchParents;
extern NSString * const kMCHAuthServiceV2Auth0User;
extern NSString * const kMCHIds;
extern NSString * const kMCHFolderIDRoot;
extern NSString * const kMCHMIMETypeFolder;
extern NSString * const kMCHContentTypeApplicationJSON;
extern NSString * const kMCHContentTypeMultipartRelated;
extern NSString * const kMCHContentTypeApplicationXWWWFormURLEncoded;
extern NSString * const kMCHPageToken;
extern NSString * const kMCHLimit;
extern NSUInteger const kMCHDefaultLimit;

NS_ASSUME_NONNULL_END
