// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import "MSClient.h"
#import "MSLogin.h"
#import "MSLoginSafariViewController.h"
#import "MSLoginSafariViewControllerUtilities.h"
#import "MSPkceState.h"
#import "MSClientConnection.h"
#import "MSLoginSerializer.h"
#import "MSJSONSerializer.h"
#import "MSUser.h"
#import "MSURLBuilder.h"

@interface MSLoginSafariViewController() <SFSafariViewControllerDelegate>

#pragma mark * Private Properties

@property (nonatomic, nullable) MSPkceState *safariLoginFlow;

@property (nonatomic, nullable) SFSafariViewController *safariViewController;

@property (nonatomic, nullable) MSLogin *webViewLogin;

@end

@implementation MSLoginSafariViewController

#pragma mark * Public Constructor Methods

- (instancetype)initWithClient:(MSClient *)client
{
    self = [super init];
    
    if (self) {
        _client = client;
        
        if ([SFSafariViewController class]) {
            _webViewLogin = [[MSLogin alloc] initWithClient:_client];
        }
    }
    
    return self;
}

#pragma mark * Public Login Methods

- (void)loginWithProvider:(NSString *)provider
                urlScheme:(NSString *)urlScheme
               parameters:(nullable NSDictionary *)parameters
               controller:(UIViewController *)controller
                 animated:(BOOL)animated
               completion:(nullable MSClientLoginBlock)completion
{
    // SafariServices API is only available on iOS 9 or later, not iOS 8 or prior.
    // When SafariServices is not avaiable, fallback to WebView based login in |MSLogin|
    // for backward compatibility.
    
    if ([SFSafariViewController class]) {
        [self safariViewControllerLoginWithProvider:provider
                                        urlScheme:urlScheme
                                         parameters:parameters
                                         controller:controller
                                           animated:animated
                                         completion:completion];
    }
    else {
        [self.webViewLogin loginWithProvider:provider
                           parameters:parameters
                           controller:controller
                             animated:animated
                           completion:completion];
    }
}

- (BOOL)resumeWithURL:(NSURL *)URL
{
    if (self.safariLoginFlow) {
        
        NSURL *codeExchangeRequestURL = [self codeExchangeRequestURLFromRedirectURL:URL];

        if (codeExchangeRequestURL) {
            [self codeExchangeWithURL:codeExchangeRequestURL];
            return YES;
        }
    }

    return NO;
}


#pragma mark * Private Login Methods

- (void)safariViewControllerLoginWithProvider:(NSString *)provider
                                    urlScheme:(NSString *)urlScheme
                                   parameters:(nullable NSDictionary *)parameters
                                   controller:(UIViewController *)controller
                                     animated:(BOOL)animated
                                   completion:(nullable MSClientLoginBlock)completion
{
    if (self.safariLoginFlow) {
        // Only one concurrent safari view controller login is allowed.
        // Ignore if there is already a pending login flow.
        return;
    }
    
    provider = [MSLoginSafariViewControllerUtilities normalizeProvider:provider];
    
    NSString *codeVerifier = [MSLoginSafariViewControllerUtilities generateCodeVerifier];

    self.safariLoginFlow = [[MSPkceState alloc] initWithProvider:provider
                                                                loginCompletion:completion
                                                                codeVerifier:codeVerifier
                                                                urlScheme:urlScheme
                                                                animated:animated];
    
    NSURL *loginURL = [MSLoginSafariViewControllerUtilities loginURLFromApplicationURL:self.client.applicationURL
                                                           provider:provider
                                                           urlScheme:urlScheme
                                                           parameters:parameters
                                                           codeVerifier:codeVerifier
                                                           codeChallengeMethod:@"S256"];

    self.safariViewController = [[SFSafariViewController alloc] initWithURL:loginURL entersReaderIfAvailable:NO];
    
    self.safariViewController.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(),^{
        [controller presentViewController:self.safariViewController animated:animated completion:nil];
    });
}

- (NSURL *)codeExchangeRequestURLFromRedirectURL:(NSURL *)URL
{
    NSURL *requestURL = nil;
    
    BOOL isRedirectURLValid = [MSLoginSafariViewControllerUtilities isRedirectURLValid:URL withUrlScheme:self.safariLoginFlow.urlScheme];
    
    if (isRedirectURLValid) {
        NSString *authorizationCode = [MSLoginSafariViewControllerUtilities authorizationCodeFromRedirectURL:URL];
        
        requestURL = [MSLoginSafariViewControllerUtilities codeExchangeURLFromApplicationURL:self.client.applicationURL
                                                         provider:self.safariLoginFlow.provider
                                                         authorizationCode:authorizationCode
                                                        codeVerifier:self.safariLoginFlow.codeVerifier];
    }
    
    return requestURL;
}

- (void)codeExchangeWithURL:(NSURL *)URL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    // Call the token endpoint for code exchange.
    // If response is 200 OK, dismiss safari view controller and call login
    // completion with user.
    // If response is non-400 error, dismiss safari view controller and
    // call login completion with response error.
    // Ignore 400 error. It means something wrong with code exchange, could be a malicious caller
    // with a bogus code verifier.
    
    MSResponseBlock responseCompletion = ^(NSHTTPURLResponse *response, NSData *data, NSError *responseError) {
        
        if (!responseError) {
            if (response.statusCode == 200) {
                
                MSUser *user = [[MSLoginSerializer loginSerializer] userFromData:data orError:&responseError];
                
                if (user && !responseError) {
                    self.client.currentUser = user;
                    
                    [self dismissSafariViewControllerAndCallbackWithUser:user responseError:nil];
                }
            }
            else if (response.statusCode == 400) {
                // Do nothing
            }
            else if (response.statusCode > 400) {
                
                responseError = [[MSJSONSerializer JSONSerializer] errorFromData:data MIMEType:response.MIMEType];
                
                [self dismissSafariViewControllerAndCallbackWithUser:nil responseError:responseError];
            }
        }
    };
    
    // Create the connection and start it
    MSClientConnection *connection = [[MSClientConnection alloc] initWithRequest:request
                                                              client:self.client
                                                              completion:responseCompletion];
    [connection start];
}

- (void)dismissSafariViewControllerAndCallbackWithUser:(MSUser *)user
                                         responseError:(NSError *)responseError
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.safariViewController dismissViewControllerAnimated:self.safariLoginFlow.animated completion:^{
            
            // Saving the loginCompletion callback before resetting safariLoginFlow to nil.
            // Call the loginCompletion at the end.
            
            MSClientLoginBlock loginCompletion = [self.safariLoginFlow.loginCompletion copy];
            
            self.safariLoginFlow = nil;
            
            loginCompletion(user, responseError);
        }];
    });
}

#pragma mark * SFSafariViewControllerDelegate Private Implementation

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    if (controller != self.safariViewController) {
        // Ignore this call if safari view controller doesn't match
        return;
    }
    
    if (!self.safariLoginFlow) {
        // Ignore this call if there is no pending login flow
        return;
    }
    
    MSClientLoginBlock loginCompletion = [self.safariLoginFlow.loginCompletion copy];

    self.safariLoginFlow = nil;
    
    NSError *error = [self errorWithDescriptionKey:@"The login operation was canceled." andErrorCode:MSLoginCanceled];
    
    loginCompletion(nil, error);
}

#pragma mark * Private NSError Generation Methods

- (NSError *) errorWithDescriptionKey:(NSString *)descriptionKey
                        andErrorCode:(NSInteger)errorCode
{
    NSString *description = NSLocalizedString(descriptionKey, nil);
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

- (NSError *)errorWithDescription:(NSString *)description
                             code:(NSInteger)code
                    internalError:(NSError *)error
{
    NSMutableDictionary *userInfo = [@{ NSLocalizedDescriptionKey: description } mutableCopy];
    
    if (error) {
        [userInfo setObject:error forKey:NSUnderlyingErrorKey];
    }
    
    return [NSError errorWithDomain:MSErrorDomain code:code userInfo:userInfo];
}

@end
