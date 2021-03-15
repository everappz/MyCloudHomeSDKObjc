//
//  MCHAuthRequest.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//https://developer.westerndigital.com/develop/wd-my-cloud-home/discover/off-device-applications/authentication.html/

@interface MCHAuthRequest : NSObject

- (NSURLRequest * _Nullable)URLRequest;

@property (nonatomic,strong)NSURL *requestURL;

@end


/*
 POST /oauth/token HTTP/1.1
 Host: <service.auth0.url>
 Content-Type: application/json
 {
 "audience": "mycloud.com",
 "client_id": "",
 "client_secret": "",
 "code": "authorize_code",
 "grant_type": "authorization_code",
 "redirect_uri": ""
 }
 */
@interface MCHTokenExchangeRequest : MCHAuthRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                  clientSecret:(NSString *)clientSecret
                          code:(NSString *)code
                   redirectURL:(NSURL *)redirectURL;

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSString *code;
@property (nonatomic,strong)NSURL *redirectURL;
@property (nonatomic,copy)NSString *clientSecret;
@property (nonatomic,copy)NSString *grantType;
@property (nonatomic,strong)NSDictionary *additionalParameters;

@end


/*
 POST /oauth/token HTTP/1.1
 Host: <service.auth0.url>
 Content-Type: application/json
 {
 "audience": "mycloud.com",
 "client_id": "",
 "client_secret": "",
 "grant_type": "refresh_token",
 "refresh_token": ""
 }
 */
@interface MCHTokenRefreshRequest : MCHAuthRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                  clientSecret:(NSString *)clientSecret
                   accessToken:(NSString *)accessToken
                  refreshToken:(NSString *)refreshToken;

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSString *refreshToken;
@property (nonatomic,copy)NSString *accessToken;
@property (nonatomic,copy)NSString *clientSecret;
@property (nonatomic,copy)NSString *grantType;
@property (nonatomic,strong)NSDictionary *additionalParameters;

@end


/*
 https://<service.auth0.url>/authorize?
 scope=openid%20offline_access%20nas_read_write%20nas_read_only%20user_read%20device_read
 &response_type=code&connection=Username-Password-Authentication&sso=false
 &audience=mycloud.com&state=my-custom-state&protocol=oauth2
 &client_id=PoWAstGBvHV1HMWI7hofM6yL653RR&redirect_uri=http%3A%2F%2Flocalhost
 */
@interface MCHAuthStartRequest : MCHAuthRequest

+ (instancetype)requestWithURL:(NSURL *)requestURL
                      clientID:(NSString *)clientID
                        scopes:(NSArray <NSString *> *)scopes
                   redirectURL:(NSURL *)redirectURL;

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSArray<NSString *> *scopes;
@property (nonatomic,strong)NSURL *redirectURL;
@property (nonatomic,strong)NSDictionary *additionalParameters;
@property (nonatomic,copy)NSString *responseType;

@end


NS_ASSUME_NONNULL_END
