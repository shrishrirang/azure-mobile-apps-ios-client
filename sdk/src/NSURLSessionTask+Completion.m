// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

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
        // Call the explicit setter so the setAssociatedObject method gets called to retain the data
        self.data = _data;
    }
    
    return _data;
}

- (void)setData:(NSMutableData *)data
{
    objc_setAssociatedObject(self, _cmd, data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
