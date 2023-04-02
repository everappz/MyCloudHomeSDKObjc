//
//  MCHAuthState.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "MCHAuthState.h"
#import "MCHAuthRequest.h"
#import "MCHNetworkClient.h"
#import "NSError+MCHSDK.h"
#import "MCHObject.h"

@interface MCHAuthState()

@property (nonatomic, strong) MCHNetworkClient *networkClient;
@property (atomic, weak) NSURLSessionDataTask *tokenUpdateTask;
@property (nonatomic, strong) NSMutableArray<MCHAccessTokenUpdateBlock> *tokenUpdateCompletionBlocks;

@end


@implementation MCHAuthState

- (instancetype)initWithClientID:(NSString * _Nullable)clientID
                    clientSecret:(NSString * _Nullable)clientSecret
                     redirectURI:(NSString * _Nullable)redirectURI
                          scopes:(NSArray<NSString *> * _Nullable)scopes
                     accessToken:(NSString * _Nullable)accessToken
                         idToken:(NSString * _Nullable)idToken
                    refreshToken:(NSString * _Nullable)refreshToken
                       tokenType:(NSString * _Nullable)tokenType
                       expiresIn:(NSNumber * _Nullable)expiresIn
                  tokenUpdateURL:(NSURL * _Nullable)tokenUpdateURL
                 tokenExpireDate:(NSDate * _Nullable)tokenExpireDate
{
    self = [super init];
    if (self) {
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.redirectURI = redirectURI;
        self.scopes = scopes;
        self.accessToken = accessToken;
        self.idToken = idToken;
        self.refreshToken = refreshToken;
        self.tokenType = tokenType;
        self.expiresIn = expiresIn;
        self.tokenUpdateURL = tokenUpdateURL;
        self.tokenExpireDate = tokenExpireDate;
    }
    return self;
}

- (MCHNetworkClient *)networkClient {
    if (_networkClient == nil) {
        _networkClient = [[MCHNetworkClient alloc] initWithURLSessionConfiguration:nil];
    }
    return _networkClient;
}

- (NSMutableArray<MCHAccessTokenUpdateBlock> *)tokenUpdateCompletionBlocks{
    if (_tokenUpdateCompletionBlocks == nil) {
        _tokenUpdateCompletionBlocks = [NSMutableArray<MCHAccessTokenUpdateBlock> new];
    }
    return _tokenUpdateCompletionBlocks;
}

- (void)addTokenUpdateCompletionBlock:(MCHAccessTokenUpdateBlock)block{
    if (block == nil){
        NSParameterAssert(NO);
        return;
    }
    MCHAccessTokenUpdateBlock copiedBlock = [block copy];
    @synchronized (self.tokenUpdateCompletionBlocks) {
        [self.tokenUpdateCompletionBlocks addObject:copiedBlock];
    }
}

- (void)processTokenUpdateCompletionBlocks{
    @synchronized (self.tokenUpdateCompletionBlocks) {
        NSString *accessToken = self.accessToken;
        NSString *idToken = self.idToken;
        NSError *tokenUpdateError = self.tokenUpdateError;
        for (MCHAccessTokenUpdateBlock block in self.tokenUpdateCompletionBlocks){
            block(accessToken,idToken,tokenUpdateError);
        }
        [self.tokenUpdateCompletionBlocks removeAllObjects];
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        _idToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"idToken"];
        _expiresIn = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"expiresIn"];
        _tokenType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"tokenType"];
        _refreshToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"refreshToken"];
        _accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
        _scopes = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"scopes"];
        _redirectURI = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"redirectURI"];
        _clientSecret = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientSecret"];
        _clientID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientID"];
        _tokenUpdateURL = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"tokenUpdateURL"];
        _tokenExpireDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"tokenExpireDate"];
        _tokenUpdateError = [aDecoder decodeObjectOfClass:[NSError class] forKey:@"tokenUpdateError"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_idToken forKey:@"idToken"];
    [aCoder encodeObject:_expiresIn forKey:@"expiresIn"];
    [aCoder encodeObject:_tokenType forKey:@"tokenType"];
    [aCoder encodeObject:_refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:_accessToken forKey:@"accessToken"];
    [aCoder encodeObject:_scopes forKey:@"scopes"];
    [aCoder encodeObject:_redirectURI forKey:@"redirectURI"];
    [aCoder encodeObject:_clientSecret forKey:@"clientSecret"];
    [aCoder encodeObject:_clientID forKey:@"clientID"];
    [aCoder encodeObject:_tokenUpdateURL forKey:@"tokenUpdateURL"];
    [aCoder encodeObject:_tokenExpireDate forKey:@"tokenExpireDate"];
    [aCoder encodeObject:_tokenUpdateError forKey:@"tokenUpdateError"];
}

#pragma mark - Token Update

- (void)completeTokenUpdateWithResponse:(NSDictionary *_Nullable)dictionary
                                  error:(NSError *_Nullable)error{
    if (dictionary != nil) {
      NSString *access_token = [MCHObject stringForKey:@"access_token" inDictionary:dictionary];
      NSNumber *expires_in = [MCHObject numberForKey:@"expires_in" inDictionary:dictionary];
      NSString *id_token = [MCHObject stringForKey:@"id_token" inDictionary:dictionary];
      NSString *refresh_token = [MCHObject stringForKey:@"refresh_token" inDictionary:dictionary];
      NSString *token_type = [MCHObject stringForKey:@"token_type" inDictionary:dictionary];

      NSParameterAssert(access_token);

      NSDate *tokenExpireDate = nil;
      if (expires_in && expires_in.longLongValue > 0){
          tokenExpireDate = [NSDate dateWithTimeIntervalSinceNow:expires_in.longLongValue];
      }

      if (access_token && access_token.length > 0) {
          self.accessToken = access_token;
      }
      if (expires_in) {
          self.expiresIn = expires_in;
      }
      if (id_token && id_token.length > 0) {
          self.idToken = id_token;
      }
      if (refresh_token && refresh_token.length > 0) {
          self.refreshToken = refresh_token;
      }
      if (token_type && token_type.length > 0) {
          self.tokenType = token_type;
      }
      if (tokenExpireDate) {
          self.tokenExpireDate = tokenExpireDate;
      }
    }
    
    self.tokenUpdateError = error;
    
    [self processTokenUpdateCompletionBlocks];
    
    if ([self.stateChangeDelegate respondsToSelector:@selector(MCHAuthStateDidChange:)]){
        [self.stateChangeDelegate MCHAuthStateDidChange:self];
    }
}

- (NSURLSessionDataTask * _Nullable)updateTokenWithCompletion:(MCHAccessTokenUpdateBlock)completion{
    
    [self addTokenUpdateCompletionBlock:completion];
    
    if (self.tokenUpdateTask) {
        return self.tokenUpdateTask;
    }
    
    MCHTokenRefreshRequest *tokenRefreshRequest =
    [MCHTokenRefreshRequest requestWithURL:self.tokenUpdateURL
                                  clientID:self.clientID
                              clientSecret:self.clientSecret
                               accessToken:self.accessToken
                              refreshToken:self.refreshToken];
    NSURLRequest *tokenRefreshURLRequest = [tokenRefreshRequest URLRequest];
    if (tokenRefreshURLRequest == nil){
        NSParameterAssert(NO);
        [self completeTokenUpdateWithResponse:nil
                                        error:[NSError MCHErrorWithCode:MCHErrorCodeCannotUpdateAccessToken]];
        return nil;
    }
    
    MCHMakeWeakSelf;
    NSURLSessionDataTask *tokenUpdateTask = [self.networkClient dataTaskWithRequest:tokenRefreshURLRequest
                                                                  completionHandler:
                                             ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [MCHNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            MCHMakeStrongSelf;
            [strongSelf completeTokenUpdateWithResponse:dictionary
                                                  error:error];
        } withData:data response:response error:error];
    }];
    self.tokenUpdateTask = tokenUpdateTask;
    [tokenUpdateTask resume];
    return tokenUpdateTask;
}

@end
