//
//  NSURLSessionTask+Completion.m
//  MicrosoftAzureMobile
//
//  Created by Damien Pontifex on 2/08/2016.
//  Copyright © 2016 Windows Azure. All rights reserved.
//

#import <objc/runtime.h>
#import "NSURLSessionTask+Completion.h"

@implementation NSURLSessionTask(Completion)
@dynamic completion;
@dynamic data;

- (MSResponseBlock)completion
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCompletion:(MSResponseBlock)completion
{
    objc_setAssociatedObject(self, _cmd, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSMutableData *)data
{
    NSMutableData *_data = objc_getAssociatedObject(self, _cmd);
    if (!_data) {
        _data = [NSMutableData data];
        self.data = _data;
    }
    
    return _data;
}

- (void)setData:(NSMutableData *)data
{
    objc_setAssociatedObject(self, _cmd, data, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
