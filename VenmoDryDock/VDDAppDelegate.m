// VDDAppDelegate.m
//
// Copyright (c) 2014 Venmo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VDDAppDelegate.h"
#import <VENVersionTracker/VENVersionTracker.h>
#import "VDDConstants.h"
#import <UIAlertView+Blocks/UIAlertView+Blocks.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSString * const InstallActionIdentifier = @"InstallActionIdentifier";
static NSString * const UpdateCategoryIdentifier = @"update";

@implementation VDDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[CrashlyticsKit]];
    [Parse setApplicationId:VDDParseAppId
                  clientKey:VDDParseClientKey];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [self startTrackingVersion];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIMutableUserNotificationAction *installAction = [UIMutableUserNotificationAction new];
        installAction.identifier = InstallActionIdentifier;
        installAction.title = NSLocalizedString(@"Install", nil);
        installAction.activationMode = UIUserNotificationActivationModeForeground;
        installAction.destructive = NO;
        installAction.authenticationRequired = YES;
        
        UIMutableUserNotificationCategory *updateCategory = [UIMutableUserNotificationCategory new];
        updateCategory.identifier = UpdateCategoryIdentifier;
        [updateCategory setActions:@[installAction] forContext:UIUserNotificationActionContextDefault];
        [updateCategory setActions:@[installAction] forContext:UIUserNotificationActionContextMinimal];
        
        NSSet *notificationCategories = [NSSet setWithObject:updateCategory];
        UIUserNotificationSettings* requestedSettings = [UIUserNotificationSettings settingsForTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge
                                                                                          categories:notificationCategories];
        [[UIApplication sharedApplication] registerUserNotificationSettings:requestedSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound ];
    }
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setChannels:@[@"global"]];
    [currentInstallation saveInBackground];
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [UIAlertView showWithTitle:@"push" message:@"got device token" cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
    }];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@", error);
    [UIAlertView showWithTitle:@"push error" message:error.localizedDescription cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    if ([userInfo[@"aps"][@"category"] isEqualToString:UpdateCategoryIdentifier] && [identifier isEqualToString:InstallActionIdentifier]) {
        NSString *installUrl = userInfo[@"install_url"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:installUrl]];
        completionHandler();
    } else {
        completionHandler();
    }
}

- (void)startTrackingVersion {
    [VENVersionTracker beginTrackingVersionForChannel:VDDChannelName
                                       serviceBaseUrl:VDDBaseUrl
                                         timeInterval:1800
                                          withHandler:^(VENVersionTrackerState state, VENVersion *version) {
                                              dispatch_sync(dispatch_get_main_queue(), ^{
                                                  if (state == VENVersionTrackerStateDeprecated || state == VENVersionTrackerStateOutdated) {
                                                      [self promptInstallForVersion:version];
                                                  }
                                              });
                                          }];
}

- (void)promptInstallForVersion:(VENVersion *)version {
    if ([UIAlertController class]) {
        UIAlertController *alert= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"New version available", nil)
                                                                      message:NSLocalizedString(@"Please install the latest version of DryDock", nil)
                                                               preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *install = [UIAlertAction actionWithTitle:NSLocalizedString(@"Install", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            [version install];
                                                   }];
        
        [alert addAction:install];
        
        [self.window.rootViewController presentViewController:alert
                                                     animated:YES
                                                   completion:nil];
        
    } else {
        [UIAlertView showWithTitle:NSLocalizedString(@"New version available", nil) message:NSLocalizedString(@"Please install the latest version of DryDock", nil) cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"Install", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            
        }];
    }
}

@end
