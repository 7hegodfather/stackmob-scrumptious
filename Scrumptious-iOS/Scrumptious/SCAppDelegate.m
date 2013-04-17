/*
 * Copyright 2012-2013 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SCAppDelegate.h"
#import "SCViewController.h"
#import "SCLoginViewController.h"
#import "StackMob.h"

// Uncomment for push notification functionality.
// #import "StackMobPush.h"

NSString *const SCSessionStateChangedNotification =
@"com.facebook.Scrumptious:SCSessionStateChangedNotification";

@interface SCAppDelegate ()

@property (strong, nonatomic) UINavigationController* navController;
@property (strong, nonatomic) SCViewController *mainViewController;

- (void)showLoginView;
- (void)loginWithFacebook;
- (void)postToImpressionEndpoint;

@end

@implementation SCAppDelegate

@synthesize navController = _navController;
@synthesize mainViewController = _mainViewController;
@synthesize client = _client;
@synthesize coreDataStore = _coreDataStore;
@synthesize managedObjectModel = _managedObjectModel;

// Uncomment for push notification functionality.
// @synthesize pushClient = _pushClient;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FBProfilePictureView class];
    [FBSettings setLoggingBehavior:[NSSet
                                    setWithObjects:FBLoggingBehaviorFBRequests,
                                    FBLoggingBehaviorFBURLConnections,
                                    nil]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.mainViewController = [[SCViewController alloc] initWithNibName:@"SCViewController_iPhone" bundle:nil];
    
    self.navController = [[UINavigationController alloc]
                          initWithRootViewController:self.mainViewController];
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    
    /*************
     StackMob Init
    **************/
    
    // Enable Cache for User's Ratings
    SM_CACHE_ENABLED = YES;
    
    // Init client and core data store
    self.client = [[SMClient alloc] initWithAPIVersion:@"1" publicKey:@"d4d1fc7c-a23b-4115-9133-1cf8aa0595a3"];
    self.coreDataStore = [self.client coreDataStoreWithManagedObjectModel:self.managedObjectModel];
    
    // Add cache fetch policy
    self.coreDataStore.cachePolicy = SMCachePolicyTryNetworkElseCache;
    
    
    __block id blockSelf = self;
    __block SMUserSession *currentSession = self.client.session;
    [self.client setTokenRefreshFailureBlock:^(NSError *error, SMFailureBlock originalFailureBlock) {
        [currentSession clearSessionInfo];
        [blockSelf loginWithFacebook];
    }];
    
    
    // See if we have a valid token for the current state.
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // To-do, show logged in view
        [self openSession];
    } else {
        // No, display the login page.
        [self showLoginView];
    }
    
    // Uncomment for push notification functionality.
    /*
    self.pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:@"YOUR_PUBLIC_KEY" privateKey:@"YOUR_PRIVATE_KEY"];
    // Add more notification types using |, i.e UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
    */
    
    // Hit impression endpoint (for FB tracking of app)
    [self postToImpressionEndpoint];
    
    return YES;
}

// Uncomment the following methods for push notification functionality.
/*
# pragma mark Push Notifications

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [[token componentsSeparatedByString:@" "] componentsJoinedByString:@""];
    
    NSLog(@"push token: %@",token);
    
    // Persist token here if you need.  User is an arbitrary string to associate with the token.
    [self.pushClient registerDeviceToken:token withUser:@"Person123" onSuccess:^{
        NSLog(@"successful push registration on StackMob");
    } onFailure:^(NSError *error) {
        NSLog(@"error registering for push on StackMob: %@", [error userInfo]);
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        NSString *cancelTitle = @"Close";
        NSString *showTitle = @"Show";
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"StackMob Message"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:cancelTitle
                                                  otherButtonTitles:showTitle, nil];
        [alertView show];
        
    } else {
        //Do stuff that you would do if the application was not active
    }
}
*/

# pragma mark Login

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)showLoginView
{
    UIViewController *topViewController = [self.navController topViewController];
    UIViewController *modalViewController = [topViewController modalViewController];
    
    // If the login screen is not already displayed, display it. If the login screen is
    // displayed, then getting back here means the login in progress did not successfully
    // complete. In that case, notify the login view so it can update its UI appropriately.
    if (![modalViewController isKindOfClass:[SCLoginViewController class]]) {
        SCLoginViewController* loginViewController = [[SCLoginViewController alloc]
                                                      initWithNibName:@"SCLoginViewController"
                                                      bundle:nil];
        [topViewController presentModalViewController:loginViewController animated:NO];
    } else {
        SCLoginViewController* loginViewController =
        (SCLoginViewController*)modalViewController;
        [loginViewController loginFailed];
    }
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen: {
            
            /*
             If our StackMob client is currently logged out,
             log them in upon logging with through Facebook
             and create a user if needed.
             */
            if ([self.client isLoggedOut]) {
                [self loginWithFacebook];
            } else {
                // Dismiss view
                UIViewController *topViewController =
                [self.navController topViewController];
                if ([[topViewController modalViewController]
                     isKindOfClass:[SCLoginViewController class]]) {
                    [topViewController dismissModalViewControllerAnimated:YES];
                }
            }
        }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to
            // be looking at the root view.
            [self.navController popToRootViewControllerAnimated:NO];
            
            [FBSession.activeSession closeAndClearTokenInformation];
            
            [self showLoginView];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:SCSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)openSession
{
    NSArray *permissions = [NSArray arrayWithObjects:@"user_photos",
                            nil];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

/*
 Login the StackMob user linked with the current Facebook session credentials.  
 This method sets a flag to automatically create a StackMob user if one doesn't already exist
 that is linked with the current Facebook session credentials. The login call is wrapped in a
 Facebook request for the current logged in user's info so we can attach the username to the
 created StackMob user.
 */
- (void)loginWithFacebook
{
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection,
       NSDictionary<FBGraphUser> *user,
       NSError *error) {
         if (!error) {
             [self.client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:user.username onSuccess:^(NSDictionary *result) {
                 
                 NSLog(@"Logged in with StackMob");
                 // Dismiss view
                 UIViewController *topViewController =
                 [self.navController topViewController];
                 if ([[topViewController modalViewController]
                      isKindOfClass:[SCLoginViewController class]]) {
                     [topViewController dismissModalViewControllerAnimated:YES];
                 }
                 
             } onFailure:^(NSError *error) {
                 
                 // Handle Error
                 NSLog(@"Error logging into StackMob, %@", error);
                 UIViewController *topViewController = [self.navController topViewController];
                 UIViewController *modalViewController = [topViewController modalViewController];
                 if ([modalViewController isKindOfClass:[SCLoginViewController class]]) {
                     SCLoginViewController* loginViewController =
                     (SCLoginViewController*)modalViewController;
                     [loginViewController loginFailed];
                 }
             }];
         } else {
             // Handle error accordingly
             NSLog(@"Error getting current Facebook user data, %@", error);
         }
         
     }];
    
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"myDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // We need to properly handle activation of the application with regards to Facebook Login
    // (e.g., returning from iOS 6.0 Login Dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)postToImpressionEndpoint
{
    NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:@"stackmob_stackmob", @"resource", @"131456347033972", @"appid", @"ios_1.4.0", @"version", nil];
    NSError *error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONReadingAllowFragments error:&error];
    NSString *payloadString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"featured_resources", @"plugin", payloadString, @"payload", nil];
    AFHTTPClient *newClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.facebook.com"]];
    [newClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    newClient.parameterEncoding = AFFormURLParameterEncoding;
    
    NSMutableURLRequest *impressionRequest = [newClient requestWithMethod:@"POST" path:@"impression.php" parameters:parameters];
    [impressionRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:impressionRequest success:nil failure:nil];
    
    [newClient enqueueHTTPRequestOperation:op];
}

@end
