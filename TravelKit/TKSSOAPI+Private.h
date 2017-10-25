//
//  TKSSOAPI+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKUserCredentials.h"
#import "TKAPIConnection+Private.h"


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - SSO API singleton -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKSSOAPI : NSObject

/** Shared sigleton */
+ (TKSSOAPI *)sharedAPI;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

// Standard supported API calls

- (void)performDeviceCredentialsFetchWithSuccess:(void (^)(TKUserCredentials *))success
    failure:(void (^)(TKAPIError *))failure;

- (void)performCredentialsRefreshWithToken:(NSString *)refreshToken
    success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure;

- (void)performUserCredentialsAuthWithUsername:(NSString *)username password:(NSString *)password
    success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure;

- (void)performUserSocialAuthWithFacebookToken:(NSString *)facebookToken googleToken:(NSString *)googleToken
    success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure;

- (void)performJWTAuthWithToken:(NSString *)jwtToken
    success:(void (^)(TKUserCredentials *))success failure:(TKAPIConnectionFailureBlock)failure;

- (void)performUserRegisterWithToken:(NSString *)accessToken
  fullName:(NSString *)fullName email:(NSString *)email password:(NSString *)password
    success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure;

- (void)performUserResetPasswordWithToken:(NSString *)accessToken email:(NSString *)email
    success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure;

@end
