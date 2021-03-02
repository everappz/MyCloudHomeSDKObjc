//
//  MCHAPIClientCache.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/20/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "MCHAPIClientCache.h"
#import "MCHAppAuthProvider.h"
#import "MCHAppAuthManager.h"
#import "MCHAPIClient.h"

@interface MCHAPIClientCache()

@property (nonatomic, strong) NSMutableDictionary<NSString *,MCHAppAuthProvider *> *authProviders;

@property (nonatomic, strong) NSMutableDictionary<NSString *,MCHAPIClient *> *apiClients;

@end


@implementation MCHAPIClientCache

+ (instancetype)sharedCache{
    static dispatch_once_t onceToken;
    static MCHAPIClientCache *sharedCache;
    dispatch_once(&onceToken, ^{
        sharedCache = [[MCHAPIClientCache alloc] init];
    });
    return sharedCache;
}

- (instancetype)init{
    self = [super init];
    if(self){
        self.authProviders = [[NSMutableDictionary<NSString *,MCHAppAuthProvider *> alloc] init];
        self.apiClients = [[NSMutableDictionary<NSString *,MCHAPIClient *> alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(authProviderDidChangeNotification:)
                                                     name:MCHAppAuthProviderDidChangeState
                                                   object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (MCHAPIClient *_Nullable)clientForIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    MCHAPIClient *client = nil;
    @synchronized (self.apiClients) {
        client = [self.apiClients objectForKey:identifier];
    }
    return client;
}

- (MCHAppAuthProvider *_Nullable)authProviderForIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    MCHAppAuthProvider *authProvider = nil;
    @synchronized (self.authProviders) {
        authProvider = [self.authProviders objectForKey:identifier];
    }
    return authProvider;
}

- (BOOL)setAuthProvider:(MCHAppAuthProvider * _Nonnull)authProvider
          forIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(authProvider);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (authProvider == nil){
        return NO;
    }
    @synchronized (self.authProviders) {
        [self.authProviders setObject:authProvider forKey:identifier];
    }
    return YES;
}

- (BOOL)setClient:(MCHAPIClient * _Nonnull)client
    forIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(client);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (client == nil){
        return NO;
    }
    @synchronized (self.apiClients) {
        [self.apiClients setObject:client forKey:identifier];
    }
    return YES;
}

- (MCHAPIClient *_Nullable)createClientForIdentifier:(NSString *_Nonnull)identifier
                                            userInfo:(NSDictionary *_Nullable)userInfo
                                           authState:(OIDAuthState *_Nonnull)authState
                                sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
{
    
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    
    if(identifier == nil || authState == nil){
        return nil;
    }
    
    MCHAppAuthProvider *authProvider = [self authProviderForIdentifier:identifier];
    NSParameterAssert(authProvider == nil);
    if(authProvider == nil) {
        authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier
                                                             userInfo:userInfo
                                                                state:authState
                                               refreshTokenParameters:[[MCHAppAuthManager sharedManager] refreshRequestParameters]];
        if(authProvider){
            [self setAuthProvider:authProvider forIdentifier:identifier];
        }
    }
    NSParameterAssert(authProvider);
    if(authProvider == nil){
        return nil;
    }
    
    MCHAPIClient *client = [[MCHAPIClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration
                                                           endpointConfiguration:nil
                                                                    authProvider:authProvider];
    NSParameterAssert(client);
    if(client){
        [self setClient:client forIdentifier:identifier];
    }
    return client;
}

- (void)authStateChanged:(OIDAuthState *)authState
           forIdentifier:(NSString *)identifier{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    if(authState == nil || identifier == nil){
        return;
    }
    
    MCHAppAuthProvider *oldProvider = [self authProviderForIdentifier:identifier];
    NSParameterAssert(oldProvider);
    MCHAppAuthProvider *authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier
                                                                             userInfo:oldProvider.userInfo
                                                                                state:authState
                                                               refreshTokenParameters:oldProvider.refreshTokenParameters];
    NSParameterAssert(authProvider);
    if(authProvider){
        [self setAuthProvider:authProvider forIdentifier:identifier];
    }
    MCHAPIClient *apiClient = [self clientForIdentifier:identifier];
    NSParameterAssert(apiClient);
    [apiClient updateAuthProvider:authProvider];
}

- (void)authProviderDidChangeNotification:(NSNotification *)notification{
    MCHAppAuthProvider *provider = notification.object;
    NSParameterAssert([provider isKindOfClass:[MCHAppAuthProvider class]]);
    if([provider isKindOfClass:[MCHAppAuthProvider class]]){
        [self authStateChanged:provider.authState forIdentifier:provider.identifier];
    }
}

@end
