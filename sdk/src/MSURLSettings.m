//
//  MSURLSettings.m
//  MicrosoftAzureMobile
//
//  Created by Damien Pontifex on 4/01/2016.
//  Copyright © 2016 Windows Azure. All rights reserved.
//

#import "MSURLSettings.h"

static NSString *const defaultTableEndpoint = @"tables";
static NSString *const defaultApiEndpoint = @"api";

@implementation MSURLSettings

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.tableEndpoint = defaultTableEndpoint;
		self.apiEndpoint = defaultApiEndpoint;
	}
	return self;
}

+ (instancetype)appSettings
{
	static id instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[[self class] alloc] init];
	});
	return instance;
}

- (void)revertToDefaultTableEndpoint
{
	self.tableEndpoint = defaultTableEndpoint;
}

- (void)revertToDefaultApiEndpoint
{
	self.apiEndpoint = defaultApiEndpoint;
}

@end
