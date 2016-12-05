// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <SafariServices/SafariServices.h>
#import "MSLoginSafariViewController.h"
#import "MSClient.h"
#import "MSJsonSerializer.h"
#import "MSTestFilter.h"
#import "MSUser.h"

@interface MSLoginSafariViewControllerTests : XCTestCase

@end

@interface MSLoginSafariViewController (Tests)

// Expose private methods for testing purpose by class category
- (BOOL)requestCodeExchangeWithProvider:(NSString *)provider
                      authorizationCode:(NSString *)authorizationCode
                           codeVerifier:(NSString *)codeVerifier
                             completion:(MSClientLoginBlock)completion;

@end

@implementation MSLoginSafariViewControllerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCodeExchange
{
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com/"];
    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:200];
    
    testFilter.onInspectResponseData = ^(NSURLRequest *request, NSData *data) {
        NSDictionary *item = @{ @"user" : @{ @"userId" : @"sid:12345678" }, @"authenticationToken" : @"token12345678" };
        return [[MSJSONSerializer JSONSerializer] dataFromItem:item idAllowed:YES ensureDictionary:NO removeSystemProperties:YES orError:nil];
    };
    
    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    MSLoginSafariViewController *loginSafariViewController = [[MSLoginSafariViewController alloc] initWithClient:filterClient];
    
    BOOL success = [loginSafariViewController requestCodeExchangeWithProvider:@"google"
                                 authorizationCode:@"xyz"
                                      codeVerifier:@"abc"
                                        completion:^(MSUser * _Nullable user, NSError * _Nullable error) {
                                            XCTAssertNotNil(user);
                                            XCTAssertEqualObjects(@"sid:12345678", user.userId);
                                            XCTAssertEqualObjects(@"token12345678", user.mobileServiceAuthenticationToken);
                                            [expectation fulfill];
    }];

    XCTAssertTrue(success);
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testCodeExchangeFailedWith400Error
{
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];
    
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com/"];
    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:400];
    
    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    MSLoginSafariViewController *loginSafariViewController = [[MSLoginSafariViewController alloc] initWithClient:filterClient];
    
    BOOL success = [loginSafariViewController requestCodeExchangeWithProvider:@"google"
                                 authorizationCode:@"xyz"
                                      codeVerifier:@"abc"
                                        completion:^(MSUser * _Nullable user, NSError * _Nullable error) {
                                            XCTAssertNil(user);
                                            XCTAssertNotNil(error);
                                            XCTAssertEqual(error.code, MSErrorNoMessageErrorCode);
                                            [expectation fulfill];
                                        }];
    
    XCTAssertFalse(success);

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testCodeExchangeFailedWithNilAuthorizationCode
{
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com/"];
    
    MSLoginSafariViewController *loginSafariViewController = [[MSLoginSafariViewController alloc] initWithClient:client];
    
    BOOL success = [loginSafariViewController requestCodeExchangeWithProvider:@"google"
                                                authorizationCode:nil
                                                     codeVerifier:@"abc"
                                                       completion:^(MSUser * _Nullable user, NSError * _Nullable error) {
                                                           XCTAssertNil(user);
                                                           XCTAssertNil(error);
                                                       }];
    
    XCTAssertFalse(success);
}

@end
