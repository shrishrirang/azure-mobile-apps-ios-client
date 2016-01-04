//
//  MSURLSettingsTests.m
//  MicrosoftAzureMobile
//
//  Created by Damien Pontifex on 4/01/2016.
//  Copyright © 2016 Windows Azure. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MSURLSettings.h"

@interface MSURLSettingsTests : XCTestCase

@end

@implementation MSURLSettingsTests

- (void)setUp
{
	[super setUp];
	
	[MSURLSettings appSettings];
}

- (void)tearDown
{
	[super tearDown];
	
	[[MSURLSettings appSettings] revertToDefaultApiEndpoint];
	[[MSURLSettings appSettings] revertToDefaultTableEndpoint];
}

- (void)testUrlSettings_Defaults
{
	MSURLSettings *settings = [MSURLSettings appSettings];
	
	XCTAssertTrue([settings.tableEndpoint isEqualToString:@"tables"]);
	XCTAssertTrue([settings.apiEndpoint isEqualToString:@"api"]);
}

- (void)testUrlSettings_tableChanges
{
	MSURLSettings *settings = [MSURLSettings appSettings];
	settings.tableEndpoint = @"api";
	
	XCTAssertTrue([[MSURLSettings appSettings].tableEndpoint isEqualToString:@"api"]);
}

- (void)testUrlSettings_revertTable
{
	MSURLSettings *settings = [MSURLSettings appSettings];
	settings.tableEndpoint = @"custom";
	
	
	XCTAssertTrue([[MSURLSettings appSettings].tableEndpoint isEqualToString:@"custom"]);
	
	[settings revertToDefaultTableEndpoint];
	
	XCTAssertTrue([[MSURLSettings appSettings].tableEndpoint isEqualToString:@"tables"]);
}

- (void)testUrlSettings_apiChanges
{
	MSURLSettings *settings = [MSURLSettings appSettings];
	settings.apiEndpoint = @"custom";
	
	XCTAssertTrue([[MSURLSettings appSettings].apiEndpoint isEqualToString:@"custom"]);
}

- (void)testUrlSettings_revertApi
{
	MSURLSettings *settings = [MSURLSettings appSettings];
	
	settings.apiEndpoint = @"custom";
	
	XCTAssertTrue([[MSURLSettings appSettings].apiEndpoint isEqualToString:@"custom"]);
	
	[settings revertToDefaultApiEndpoint];
	
	XCTAssertTrue([[MSURLSettings appSettings].apiEndpoint isEqualToString:@"api"]);
}

@end
