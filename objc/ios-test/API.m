//
//  API.m
//  ios-test
//
//  Created by Patricia Marie Cesar on 5/23/16.
//  Copyright © 2016 ServiceSeeking. All rights reserved.
//

#import "API.h"

#import "Config.h"
#import "URL.h"
#import "Keys.h"

#import "User.h"

#import "NSDictionary+Helper.h"

static NSString * const HTTPHeaderAccept = @"application/vnd.api+json; version=1";
static NSString * const HTTPHeaderAuthorization = @"Basic c3NzdGFnaW5nOnNzVDNzdDFuZyE=";
static NSString * const HTTPHeaderContentType = @"application/vnd.api+json";

static API *sharedClient;

@interface API ()

@property (strong, nonatomic) NSMutableURLRequest *apiRequest;

@end

@implementation API

+ (instancetype)sharedClient {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[API alloc] init];
        sharedClient.apiRequest = [[NSMutableURLRequest alloc] init];
        [sharedClient setRequestHeaders];
    });
    
    return sharedClient;
}

#pragma mark - Login

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
        completionHandler:(HTTPRequestCompletionBlock)completionHandler {
    
    NSDictionary *usernameAndPassword = @{kEmail: username, kPassword: password};
    NSDictionary *typeAndAttributes = @{kType: @"user_sessions", kAttributes: usernameAndPassword};
    NSMutableDictionary *parameters = @{kData: typeAndAttributes}.mutableCopy;
    
    [self requestWithMethod:@"POST" path:PATH_SIGN_IN parameters:parameters completionHandler:completionHandler];
}

#pragma mark - Leads

- (void)getLeadsListingWithCompletionHandler:(HTTPRequestCompletionBlock)completionHandler {
    [self includeToken];
    [self requestWithMethod:@"GET" path:PATH_LEADS parameters:nil completionHandler:completionHandler];
}

#pragma mark - Private methods

- (void)setRequestHeaders {
    
    [self.apiRequest addValue:HTTPHeaderAccept forHTTPHeaderField:@"Accept"];
    [self.apiRequest addValue:HTTPHeaderAuthorization forHTTPHeaderField:@"Authorization"];
    [self.apiRequest addValue:HTTPHeaderContentType forHTTPHeaderField:@"Content-Type"];
    
}

- (void)requestWithMethod:(NSString *)method path:(NSString *)path
               parameters:(NSDictionary *)parameters
        completionHandler:(HTTPRequestCompletionBlock)completionHandler{
    
    self.apiRequest.HTTPMethod = method;
    self.apiRequest.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_STAGING, path]];
    self.apiRequest.HTTPBody = [parameters convertToData];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:self.apiRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                         
         if (data == nil) {
             completionHandler(nil);
         } else {
             NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    #if PRINT_RESPONSE == 1
             NSLog(@"\nURL: %@ \nMETHOD: %@ \nPARAMS: %@ \nRESPONSE: %@",
                   self.apiRequest.URL, self.apiRequest.HTTPMethod, parameters, responseDictionary);
    #endif
             completionHandler(responseDictionary);
         }
     }] resume];
}

#pragma mark - Token Handler

- (NSString *)extractTokenFromDictionary:(NSDictionary *)dict {
    
    if (dict && dict[kMeta][kToken]) {
        return dict[kMeta][kToken];
    }
    return nil;
}

- (void)includeToken {
    [self.apiRequest setValue:[NSString stringWithFormat:@"%@, Token token=%@", HTTPHeaderAuthorization, [User sharedUserInstance].token] forHTTPHeaderField:@"Authorization"];
}

@end
