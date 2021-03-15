//
//  MCHAuthRequest.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "MCHAuthRequest.h"
#import "MCHNetworkClient.h"
#import "MCHScopeUtilities.h"

@implementation MCHAuthRequest

- (NSURLRequest * _Nullable)URLRequest {
    NSParameterAssert(NO);
    return nil;
}

@end


@implementation MCHTokenExchangeRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                  clientSecret:(NSString *)clientSecret
                          code:(NSString *)code
                   redirectURL:(NSURL *)redirectURL{
    MCHTokenExchangeRequest *request = [MCHTokenExchangeRequest new];
    request.requestURL = requestURL;
    request.clientID = clientID;
    request.clientSecret = clientSecret;
    request.redirectURL = redirectURL;
    request.code = code;
    request.grantType = @"authorization_code";
    request.additionalParameters = @{@"audience":@"mycloud.com"};
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = self.requestURL;
    if (tokenRequestURL == nil){
        NSParameterAssert(NO);
        return nil;
    }
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:tokenRequestURL] mutableCopy];
    URLRequest.HTTPMethod = @"POST";
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableDictionary *bodyParams = [NSMutableDictionary new];
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [bodyParams setObject:self.clientID forKey:@"client_id"];
    }
    NSParameterAssert(self.clientSecret);
    if (self.clientSecret) {
        [bodyParams setObject:self.clientSecret forKey:@"client_secret"];
    }
    NSParameterAssert(self.code);
    if (self.code) {
        [bodyParams setObject:self.code forKey:@"code"];
    }
    NSParameterAssert(self.grantType);
    if (self.grantType) {
        [bodyParams setObject:self.grantType forKey:@"grant_type"];
    }
    NSParameterAssert(self.redirectURL);
    if (self.redirectURL.absoluteString) {
        [bodyParams setObject:[self.redirectURL.absoluteString stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"] forKey:@"redirect_uri"];
    }
    if (self.additionalParameters){
        [bodyParams addEntriesFromDictionary:self.additionalParameters];
    }
    NSData *body = [MCHNetworkClient createJSONBodyWithParameters:bodyParams];
    [URLRequest setHTTPBody:body];
    [URLRequest addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
    [MCHNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end

@implementation MCHTokenRefreshRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                  clientSecret:(NSString *)clientSecret
                   accessToken:(NSString *)accessToken
                  refreshToken:(NSString *)refreshToken{
    MCHTokenRefreshRequest *request = [MCHTokenRefreshRequest new];
    request.requestURL = requestURL;
    request.clientID = clientID;
    request.clientSecret = clientSecret;
    request.accessToken = accessToken;
    request.refreshToken = refreshToken;
    request.grantType = @"refresh_token";
    request.additionalParameters = @{@"audience":@"mycloud.com"};
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = self.requestURL;
    if (tokenRequestURL == nil){
        NSParameterAssert(NO);
        return nil;
    }
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:tokenRequestURL] mutableCopy];
    URLRequest.HTTPMethod = @"POST";
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [URLRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.accessToken] forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *bodyParams = [NSMutableDictionary new];
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [bodyParams setObject:self.clientID forKey:@"client_id"];
    }
    NSParameterAssert(self.grantType);
    if (self.grantType) {
        [bodyParams setObject:self.grantType forKey:@"grant_type"];
    }
    NSParameterAssert(self.refreshToken);
    if (self.refreshToken) {
        [bodyParams setObject:self.refreshToken forKey:@"refresh_token"];
    }
    NSParameterAssert(self.clientSecret);
    if (self.clientSecret) {
        [bodyParams setObject:self.clientSecret forKey:@"client_secret"];
    }
    if (self.additionalParameters){
        [bodyParams addEntriesFromDictionary:self.additionalParameters];
    }
    NSData *body = [MCHNetworkClient createJSONBodyWithParameters:bodyParams];
    [URLRequest setHTTPBody:body];
    [URLRequest addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
    [MCHNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end

@implementation MCHAuthStartRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                        scopes:(NSArray <NSString *> *)scopes
                   redirectURL:(NSURL *)redirectURL{
    MCHAuthStartRequest *request = [MCHAuthStartRequest new];
    request.requestURL = requestURL;
    request.clientID = clientID;
    request.scopes = scopes;
    request.redirectURL = redirectURL;
    request.responseType = @"code";
    request.additionalParameters = @{
        @"audience":@"mycloud.com",
        @"connection":@"Username-Password-Authentication",
        @"sso":@"false",
        @"protocol":@"oauth2"
    };
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = self.requestURL;
    if (tokenRequestURL == nil){
        NSParameterAssert(NO);
        return nil;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [parameters setObject:self.clientID forKey:@"client_id"];
    }
    NSParameterAssert(self.scopes);
    if (self.scopes) {
        [parameters setObject:[MCHScopeUtilities scopesWithArray:self.scopes] forKey:@"scope"];
    }
    NSParameterAssert(self.responseType);
    if (self.responseType) {
        [parameters setObject:self.responseType forKey:@"response_type"];
    }
    NSParameterAssert(self.redirectURL);
    if (self.redirectURL) {
        [parameters setObject:self.redirectURL.absoluteString forKey:@"redirect_uri"];
    }
    if (self.additionalParameters){
        [parameters addEntriesFromDictionary:self.additionalParameters];
    }
    
    
    NSURL *requestURL = [MCHNetworkClient  URLByReplacingQueryParameters:parameters
                                                                   inURL:tokenRequestURL];
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:requestURL] mutableCopy];
    URLRequest.HTTPMethod = @"GET";
    [MCHNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end

