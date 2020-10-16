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

- (MCHAPIClient *)clientForIdentifier:(NSString *)identifier
                            authState:(OIDAuthState *)authState{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    
    if(identifier && authState){
        @synchronized (self) {
            MCHAPIClient *client = [self.apiClients objectForKey:identifier];
            if(client){
                return client;
            }
            
            MCHAppAuthProvider *authProvider = [self.authProviders objectForKey:identifier];
            if(authProvider==nil){
                authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier state:authState];
                if(authProvider){
                    [self.authProviders setObject:authProvider forKey:identifier];
                }
            }
            NSParameterAssert(authProvider);
            if(authProvider==nil){
                return nil;
            }
            client = [[MCHAPIClient alloc] initWithSessionConfiguration:nil
                                                  endpointConfiguration:nil
                                                           authProvider:authProvider
                                                            authZeroURL:[MCHAppAuthManager sharedManager].authZeroURL];
            NSParameterAssert(client);
            if(client){
                [self.apiClients setObject:client forKey:identifier];
            }
            return client;
        }
    }
    return nil;
}

- (void)authStateChanged:(OIDAuthState *)authState
           forIdentifier:(NSString *)identifier{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    if(authState && identifier){
        @synchronized (self) {
            MCHAppAuthProvider *authProvider = [[MCHAppAuthProvider alloc] initWithIdentifier:identifier
                                                                                        state:authState];
            NSParameterAssert(authProvider);
            if(authProvider){
                [self.authProviders setObject:authProvider forKey:identifier];
            }
            [self.apiClients objectForKey:identifier].authProvider = authProvider;
        }
    }
}

- (void)authProviderDidChangeNotification:(NSNotification *)notification{
    MCHAppAuthProvider *provider = notification.object;
    NSParameterAssert([provider isKindOfClass:[MCHAppAuthProvider class]]);
    if([provider isKindOfClass:[MCHAppAuthProvider class]]){
        [self authStateChanged:provider.authState
                 forIdentifier:provider.identifier];
    }
}

@end
