// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

/** 
	Settings that control the URLs used for table and custom
	api endpoints for the client
 */

@interface MSURLSettings : NSObject

/** @name App wide settings object */

/**
 Gets the shared app settings object
 */
+ (nonnull instancetype)appSettings;

/// The path prefix used for the URL of the table endpoint
@property (copy, nonatomic, nonnull) NSString *tableEndpoint;

/// Reset the table endpoint to the Service default
- (void)revertToDefaultTableEndpoint;

/// The path prefix used for the URL of the api endpoint
@property (nonatomic, copy, nullable) NSString *apiEndpoint;

/// Reset the api endpoint to the Service default
- (void)revertToDefaultApiEndpoint;

// TODO: Look at adding configuration of login URLs to this header

@end
