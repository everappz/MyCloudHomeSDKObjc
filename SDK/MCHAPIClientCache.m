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
#import "MCHAuthState.h"

@interface MCHAPIClientCache()

@property (nonatomic, strong) NSMutableDictionary<NSString *,MCHAppAuthProvider *> *authProviders;
@property (nonatomic, strong) NSMutableDictionary<NSString *,MCHAPIClient *> *apiClients;
@property (nonatomic, strong) NSRecursiveLock *stateLock;

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
    if (self) {
        self.stateLock = [NSRecursiveLock new];
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

- (MCHAPIClient *_Nullable)clientForIdentifier:(NSString * _Nonnull)identifier {
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    
    MCHAPIClient *client = nil;
    [self.stateLock lock];
    client = [self.apiClients objectForKey:identifier];
    [self.stateLock unlock];
    return client;
}

- (MCHAppAuthProvider *_Nullable)authProviderForIdentifier:(NSString * _Nonnull)identifier {
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    
    MCHAppAuthProvider *authProvider = nil;
    [self.stateLock lock];
    authProvider = [self.authProviders objectForKey:identifier];
    [self.stateLock unlock];
    return authProvider;
}

- (BOOL)setAuthProvider:(MCHAppAuthProvider * _Nonnull)authProvider forIdentifier:(NSString * _Nonnull)identifier {
    NSParameterAssert(authProvider);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (authProvider == nil){
        return NO;
    }
    
    [self.stateLock lock];
    [self.authProviders setObject:authProvider forKey:identifier];
    [self.stateLock unlock];
    return YES;
}

- (BOOL)setClient:(MCHAPIClient * _Nonnull)client forIdentifier:(NSString * _Nonnull)identifier {
    NSParameterAssert(client);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (client == nil){
        return NO;
    }
    
    [self.stateLock lock];
    [self.apiClients setObject:client forKey:identifier];
    [self.stateLock unlock];
    return YES;
}

- (MCHAPIClient *_Nullable)createClientForIdentifier:(NSString *_Nonnull)identifier
                                           authState:(MCHAuthState *_Nonnull)authState
                                sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    
    if (identifier == nil || authState == nil) {
        return nil;
    }
    
    MCHAppAuthProvider *authProvider = [self authProviderForIdentifier:identifier];
    if (authProvider == nil) {
        authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier state:authState];
        if (authProvider) {
            [self setAuthProvider:authProvider forIdentifier:identifier];
        }
    }
    NSParameterAssert(authProvider);
    if (authProvider == nil) {
        return nil;
    }
    
    MCHAPIClient *client = [[MCHAPIClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration
                                                           endpointConfiguration:nil
                                                                    authProvider:authProvider];
    NSParameterAssert(client);
    if (client) {
        [self setClient:client forIdentifier:identifier];
    }
    return client;
}

- (void)updateAuthState:(MCHAuthState *_Nonnull)authState
          forIdentifier:(NSString *_Nonnull)identifier{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    if(authState == nil || identifier == nil){
        return;
    }
    
    MCHLog(@"authStateChanged: %@ forIdentifier: %@",authState.accessToken,identifier);
    MCHAppAuthProvider *authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier
                                                                                state:authState];
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
        MCHLog(@"authProviderDidChangeNotification: %@ forIdentifier: %@",provider.authState.accessToken,provider.identifier);
    }
}

@end
