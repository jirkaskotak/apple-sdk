//
//  TKSSOAPI.m
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSSOAPI+Private.h"
#import "TKUserSettings+Private.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark Definitions -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define tkAPIEndpoint        @"https://auth.sygic.com"
#define tkClientID           @"sdk.sygictravel.ios"

#ifdef DEBUG
#undef  tkAPIEndpoint
#define tkAPIEndpoint        @"https://tripomatic-auth-master-testing.sygic.com"
#undef  tkClientID
#define tkClientID           @"sygictravel_ios_sdk_demo"
#endif

// SSO endpoint URLs // TODO: Remove testing stage
NSString *const TKSSOEndpointURL = tkAPIEndpoint;

#define objectOrNull(x)      (x ?: [NSNull null])

#if TARGET_OS_OSX == 1
#define tkPlatform @"macos"
#endif // TARGET_OS_OSX

#if TARGET_OS_IOS == 1
#define tkPlatform @"ios"
#endif // TARGET_OS_IOS

#if TARGET_OS_TV == 1
#define tkPlatform @"tvos"
#endif // TARGET_OS_TV

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - SSO API singleton -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKSSOAPI ()

@property (nonatomic, copy) NSString *apiURL;

@end

@implementation TKSSOAPI

#pragma mark -
#pragma mark Shared instance

+ (TKSSOAPI *)sharedAPI
{
	static TKSSOAPI *shared = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ shared = [[self alloc] init]; });
	return shared;
}

+ (NSURLSession *)sharedSession
{
	static NSURLSession *ssoSession = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//		config.timeoutIntervalForRequest = 12.0;
//		config.URLCache = nil;
		ssoSession = [NSURLSession sessionWithConfiguration:config];
	});

	return ssoSession;
}

- (NSString *)domain
{
	return TKSSOEndpointURL;
}


////////////////////
#pragma mark - Request workers
////////////////////


- (void)performRequest:(NSURLRequest *)request
            completion:(void (^)(NSInteger status, NSDictionary *response, NSError *error))completion
{
	[[[self.class sharedSession] dataTaskWithRequest:request
	  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		if (error) {
			if (completion) completion(0, nil, [TKAPIError errorWithCode:error.code userInfo:error.userInfo]);
			return;
		}

		if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
			if (completion) completion(0, nil, [TKAPIError errorWithCode:-349852 userInfo:nil]);
			return;
		}

		NSInteger status = ((NSHTTPURLResponse *)response).statusCode;

		NSDictionary *resp = nil;

		if (data.length)
			resp = [[NSJSONSerialization JSONObjectWithData:data
				options:(NSJSONReadingOptions)0 error:NULL] parsedDictionary];

		if (status < 200 || status >= 300) {
			if (completion) completion(status, nil, [TKAPIError errorWithCode:status userInfo:@{
				NSDebugDescriptionErrorKey: resp[@"type"] ?: @"",
				NSLocalizedDescriptionKey: resp[@"detail"] ?: @"",
				NSLocalizedFailureReasonErrorKey: resp[@"detail"] ?: @"",
			}]);
			return;
		}

		if (completion) completion(status, resp, nil);

	}] resume];
}

+ (NSMutableURLRequest *)standardRequestWithURL:(NSURL *)URL data:(NSData *)data
{
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
	req.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	req.timeoutInterval = 12.0;
	req.HTTPMethod = @"POST";
	req.HTTPBody = data;

	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[req setValue:[@(data.length) stringValue] forHTTPHeaderField:@"Content-Length"];

	return req;
}


////////////////////
#pragma mark - Requests
////////////////////


- (void)performDeviceCredentialsFetchWithSuccess:(void (^)(TKUserCredentials *))success failure:(void (^)(TKAPIError *))failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"grant_type": @"client_credentials",
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKUserCredentials *credentials = [[TKUserCredentials alloc] initFromDictionary:response];

		if (credentials && success) success(credentials);
		if (!credentials && failure) failure([TKAPIError errorWithCode:-20934 userInfo:error.userInfo]);

	}];
}

- (void)performCredentialsRefreshWithToken:(NSString *)refreshToken
	success:(void (^)(TKUserCredentials *))success failure:(void (^)(TKAPIError *))failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"grant_type": @"refresh_token",
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
		@"refresh_token": objectOrNull(refreshToken),
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKUserCredentials *credentials = [[TKUserCredentials alloc] initFromDictionary:response];

		if (credentials && success) success(credentials);
		if (!credentials && failure) failure([TKAPIError errorWithCode:-20935 userInfo:error.userInfo]);

	}];
}

- (void)performUserCredentialsAuthWithUsername:(NSString *)username password:(NSString *)password
	success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"grant_type": @"password",
		@"username": objectOrNull(username),
		@"password": objectOrNull(password),
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKUserCredentials *credentials = [[TKUserCredentials alloc] initFromDictionary:response];

		if (credentials && success) success(credentials);
		if (!credentials && failure) failure([TKAPIError errorWithCode:-20936 userInfo:error.userInfo]);

	}];
}

- (void)performUserSocialAuthWithFacebookToken:(NSString *)facebookToken googleToken:(NSString *)googleToken
	success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSString *accessToken = facebookToken ?: googleToken;
	NSString *type = facebookToken ? @"facebook" : googleToken ? @"google" : nil;

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"grant_type": objectOrNull(type),
		@"access_token": objectOrNull(accessToken),
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKUserCredentials *credentials = [[TKUserCredentials alloc] initFromDictionary:response];

		if (credentials && success) success(credentials);
		if (!credentials && failure) failure([TKAPIError errorWithCode:-20937 userInfo:error.userInfo]);

	}];
}

- (void)performJWTAuthWithToken:(NSString *)jwtToken
	success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"grant_type": @"external",
		@"token": objectOrNull(jwtToken),
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKUserCredentials *credentials = [[TKUserCredentials alloc] initFromDictionary:response];

		if (credentials && success) success(credentials);
		if (!credentials && failure) failure([TKAPIError errorWithCode:-20938 userInfo:error.userInfo]);

	}];
}

- (void)performUserRegisterWithToken:(NSString *)accessToken fullName:(NSString *)fullName email:(NSString *)email
	password:(NSString *)password success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure
{
	NSString *path = @"/user/register";

	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];

	NSDictionary *post = @{
		@"client_id": tkClientID,
		@"device_code": [TKUserSettings sharedSettings].uniqueID,
		@"device_platform": tkPlatform,
		@"username" : objectOrNull(email),
		@"password" : objectOrNull(password),
		@"email" : objectOrNull(email),
		@"name" : objectOrNull(fullName),
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];

	[self performRequest:request completion:
	 ^(NSInteger status, NSDictionary * __unused response, NSError *error) {

		if (status == 200) { if (success) success(); }
		else if (failure) failure([TKAPIError errorWithCode:-20939 userInfo:error.userInfo]);

	}];
}

- (void)performUserResetPasswordWithToken:(NSString *)accessToken email:(NSString *)email
	success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure
{
	NSString *path = @"/user/reset-password";

	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];

	NSData *data = [@{ @"email" : objectOrNull(email) } asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary * __unused response, NSError *error) {

		if (error) {
			if (failure) failure([TKAPIError errorWithCode:error.code userInfo:error.userInfo]);
			return;
		}

		if (success) success();

	}];
}

@end
