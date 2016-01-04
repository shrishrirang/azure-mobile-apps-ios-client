//
//  MSURLSettings.h
//  MicrosoftAzureMobile
//
//  Created by Damien Pontifex on 4/01/2016.
//  Copyright © 2016 Windows Azure. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end
