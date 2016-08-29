// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "MSClient.h"
#import "MSJsonSerializer.h"
#import "MSLogin.h"
#import "MSTestFilter.h"
#import "MSUser.h"

@interface MSLoginTests : XCTestCase {
    BOOL done;
}

@end


@implementation MSLoginTests

#pragma mark * Setup and TearDown

- (void)setUp {
    NSLog(@"%@ setUp", self.name);
    
    done = NO;
}

- (void)tearDown {
    NSLog(@"%@ tearDown", self.name);
}

#pragma mark * Refresh User Tests

- (void)testRefreshUser
{
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com"];

    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:200];
    
    testFilter.onInspectResponseData = ^(NSURLRequest *request, NSData *data) {
        NSDictionary *item = @{ @"user" : @{ @"userId" : @"sid:12345678" }, @"authenticationToken" : @"token12345678" };
        return [[MSJSONSerializer JSONSerializer] dataFromItem:item idAllowed:YES ensureDictionary:NO removeSystemProperties:YES orError:nil];
    };
    
    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    // Invoke the API
    [filterClient refreshUserWithCompletion:
     ^(MSUser *user, NSError *error) {
         XCTAssertNil(error);
         XCTAssertNotNil(user);
         XCTAssertEqualObjects(user.userId, @"sid:12345678");
         XCTAssertEqualObjects(user.mobileServiceAuthenticationToken, @"token12345678");
         done = YES;
     }];
    
    XCTAssertTrue([self waitForTest:1], @"Test timed out.");
}

- (void)testRefreshUser400Error
{
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com"];
    
    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:400];
    
    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    // Invoke the API
    [filterClient refreshUserWithCompletion:
     ^(MSUser *user, NSError *error) {
         XCTAssertNotNil(error);
         XCTAssertEqual(error.code, MSRefreshBadRequest);
         done = YES;
     }];
    
    XCTAssertTrue([self waitForTest:1], @"Test timed out.");
}

- (void)testRefreshUser401Error
{
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com"];
    
    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:401];

    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    // Invoke the API
    [filterClient refreshUserWithCompletion:
     ^(MSUser *user, NSError *error) {
         XCTAssertNotNil(error);
         XCTAssertEqual(error.code, MSRefreshUnauthorized);
         done = YES;
     }];
    
    XCTAssertTrue([self waitForTest:1], @"Test timed out.");
}

- (void)testRefreshUser403Error
{
    MSClient *client = [MSClient clientWithApplicationURLString:@"http://someURL.com"];
    
    MSTestFilter *testFilter = [MSTestFilter testFilterWithStatusCode:403];
    
    MSClient *filterClient = [client clientWithFilter:testFilter];
    
    // Invoke the API
    [filterClient refreshUserWithCompletion:
     ^(MSUser *user, NSError *error) {
         XCTAssertNotNil(error);
         XCTAssertEqual(error.code, MSRefreshForbidden);
         done = YES;
     }];
    
    XCTAssertTrue([self waitForTest:1], @"Test timed out.");
}

#pragma mark * Async Test Helper Method


-(BOOL) waitForTest:(NSTimeInterval)testDuration {
    
    NSDate *timeoutAt = [NSDate dateWithTimeIntervalSinceNow:testDuration];
    
    while (!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutAt];
        if([timeoutAt timeIntervalSinceNow] <= 0.0) {
            break;
        }
    };
    
    return done;
}


@end
