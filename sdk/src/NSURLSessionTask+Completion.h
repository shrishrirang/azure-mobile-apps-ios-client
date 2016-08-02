//
//  NSURLSessionTask+Completion.h
//  MicrosoftAzureMobile
//
//  Created by Damien Pontifex on 2/08/2016.
//  Copyright © 2016 Windows Azure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSBlockDefinitions.h"

@interface NSURLSessionTask(Completion)

/**
 Completion block to be executed on task being completed
 */
@property (nonatomic) MSResponseBlock completion;

/**
 Data instance used for appending when receiving new data through task
 */
@property (nonatomic) NSMutableData *data;
@end
