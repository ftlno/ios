//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SHCSplitViewController.h"
#import "POSOAuthManager.h"
#import "SHCLoginViewController.h"
#import "POSLetterViewController.h"
#import "SHCAppDelegate.h"
#import "Digipost-Swift.h"

@interface SHCSplitViewController ()

@property (weak, nonatomic, readonly) POSLetterViewController *letterViewController;

@end

@implementation SHCSplitViewController

#pragma mark - NSObject

- (void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kShowLoginViewControllerNotificationName
                                                      object:nil];
    }
    @catch (NSException *exception)
    {
        //        DDLogWarn(@"Caught an exception: %@", exception);
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    @try {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(presentLoginViewController:)
                                                     name:kShowLoginViewControllerNotificationName
                                                   object:nil];
    }
    @catch (NSException *exception)
    {
        //        DDLogWarn(@"Caught an exception: %@", exception);
    }

    POSLetterViewController *letterViewController = self.letterViewController;

    if (letterViewController) {
        self.delegate = letterViewController;

        SHCAppDelegate *appDelegate = (SHCAppDelegate*) [UIApplication sharedApplication].delegate;
        appDelegate.letterViewController = letterViewController;
    }
    if ([OAuthToken isUserLoggedIn] == NO) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowLoginViewControllerNotificationName object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([Guide shouldShowOnboardingGuide] == NO) {

        if ([OAuthToken isUserLoggedIn]) {

            if ([Guide shouldShowWhatsNewGuide]) {
                [self presentNewFeatures];
            }
        }
    }
}

#pragma mark - Properties

- (POSLetterViewController *)letterViewController
{
    POSLetterViewController *letterViewController = nil;

    UINavigationController *detailNavigationController = [self.viewControllers lastObject];
    if ([detailNavigationController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topViewController = detailNavigationController.topViewController;
        if ([topViewController isKindOfClass:[POSLetterViewController class]]) {
            letterViewController = (POSLetterViewController *)topViewController;
        }
    }

    return letterViewController;
}

#pragma mark - Private methods

- (void)presentLoginViewController:(NSNotification *)notification
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        POSLetterViewController *letterViewController = self.letterViewController;
        if (letterViewController) {
            [letterViewController.masterViewControllerPopoverController dismissPopoverAnimated:YES];
        }
        [self performSegueWithIdentifier:kPresentLoginModallyIdentifier
                                  sender:nil];
        NSDictionary *userInfo = notification.userInfo;
        if (userInfo) {
            if ([userInfo[@"alert"] isMemberOfClass:[UIAlertController class]]) {
                UIAlertController *alertController = userInfo[@"alert"];
                [self.presentedViewController presentViewController:alertController animated:YES completion:nil];
            }
        }
    });
}

- (void)presentNewFeatures
{
    [Guide setOnboaringHasBeenWatched];
    UIStoryboard *newFeaturesStoryboard = [UIStoryboard storyboardWithName:@"NewFeatures" bundle:nil];
    UINavigationController *navigationController = (id)[newFeaturesStoryboard instantiateInitialViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)presentLoginViewController
{

}
@end
