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

#import <FacebookSDK/FBRequest.h>
#import "SCViewController.h"
#import "SCAppDelegate.h"
#import "SCMealViewController.h"
#import "SCRatingsViewController.h"
#import "SCRateViewController.h"
#import "SCProtocols.h"
#import "StackMob.h"
#import "Rating.h"

@interface SCViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, FBFriendPickerDelegate, FBPlacePickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
}

@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) NSArray* selectedFriends;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) FBPlacePickerViewController *placePickerController;
@property (strong, nonatomic) NSObject<FBGraphPlace>* selectedPlace;
@property (strong, nonatomic) SCMealViewController *mealViewController;
@property (strong, nonatomic) NSString* selectedMeal;
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (strong, nonatomic) UIImage* selectedPhoto;
@property (strong, nonatomic) UIPopoverController *popover;

// Properties for attaching a rating to the anncouncement
@property (strong, nonatomic) SCRatingsViewController *ratingsViewController;
@property (strong, nonatomic) SCRateViewController *rateViewController;
@property (nonatomic) int selectedRating;
@property (strong, nonatomic) NSString *ratingComment;

- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal;
- (void)postPhotoThenOpenGraphAction;
- (void)postOpenGraphActionWithPhotoURL:(NSString*)photoURL;

// Method for attaching rating to announcement using StackMob
- (void)createNewRatingForPlace:(NSString *)place meal:(NSString *)meal rating:(int)rating comment:(NSString *)comment;

// Additional method to reset the menu after an announcement has been made
- (void)resetMenu;

@end

@implementation SCViewController
@synthesize friendPickerController = _friendPickerController;
@synthesize selectedFriends = _selectedFriends;
@synthesize locationManager = _locationManager;
@synthesize placePickerController = _placePickerController;
@synthesize selectedPlace = _selectedPlace;
@synthesize mealViewController = _mealViewController;
@synthesize selectedMeal = _selectedMeal;
@synthesize imagePicker = _imagePicker;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize popover = _popover;
@synthesize ratingsViewController = _ratingsViewController;
@synthesize rateViewController = _rateViewController;
@synthesize selectedRating = _selectedRating;
@synthesize ratingComment = _ratingComment;

- (SCAppDelegate *)appDelegate
{
    return (SCAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    /*
     For UI purposes, assign the Logout button to the left bar button item,
     and assign the My Ratings view to the right bar button item.
     */
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Logout"
                                              style:UIBarButtonItemStyleBordered
                                              target:self
                                              action:@selector(logoutButtonWasPressed:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@"My Ratings"
                                             style:UIBarButtonItemStyleBordered
                                             target:self
                                             action:@selector(ratingsButtonWasPressed:)];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:SCSessionStateChangedNotification
     object:nil];
    
    self.title = @"Scrumptious";
    
    // Location Manager Setup
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // We don't want to be notified of small changes in location,
    // preferring to use our last cached results, if any.
    self.locationManager.distanceFilter = 50;
    [self.locationManager startUpdatingLocation];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 Update this method for StackMob to first logout the current StackMob user,
 followed by closing the Facebook session.
 */
-(void)logoutButtonWasPressed:(id)sender {
    
    [[self.appDelegate client] logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Logged out of StackMob");
        [FBSession.activeSession closeAndClearTokenInformation];
    } onFailure:^(NSError *error) {
        // Handle logout error
    }];
}

/*
 Method attached to right bar button item which shows
 the My Ratings view.
 */
- (void)ratingsButtonWasPressed:(id)sender {
    
    if (!self.ratingsViewController) {
        self.ratingsViewController = [[SCRatingsViewController alloc]
                                   initWithNibName:@"SCRatingsViewController" bundle:nil];
    }
    
    [self.navigationController pushViewController:self.ratingsViewController animated:YES];
    
}

- (void)viewDidUnload {
    
    self.imagePicker = nil;
    self.popover = nil;
    self.friendPickerController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setUserNameLabel:nil];
    [self setUserProfileImage:nil];
    [self setMenuTableView:nil];
    [self setAnnounceButton:nil];
    [self setSpinner:nil];
    [super viewDidUnload];
}

- (void)sessionStateChanged:(NSNotification*)notification {
    [self populateUserDetails];
}

- (void)populateUserDetails
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 self.userNameLabel.text = user.name;
                 self.userProfileImage.profileID = user.id;
             }
         }];
    }
}

/*
 Method to clear out the currently
 selected items, effectively resetting
 the menu after an announcement.
 */
- (void)resetMenu
{
    self.mealViewController = nil;
    self.rateViewController = nil;
    self.friendPickerController = nil;
    self.placePickerController = nil;
    self.imagePicker = nil;
    
    self.selectedMeal = nil;
    self.selectedRating = 0;
    self.selectedFriends = nil;
    self.selectedPlace = nil;
    self.selectedPhoto = nil;
    self.ratingComment = nil;
    [self updateSelections];
}

# pragma mark - OG

- (IBAction)announce:(id)sender {
    [self.spinner startAnimating];
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        
        [FBSession.activeSession
         requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
         defaultAudience:FBSessionDefaultAudienceFriends
         completionHandler:^(FBSession *session, NSError *error) {
             if (!error) {
                 // re-call assuming we now have the permission
                 [self announce:sender];
             }
         }];
    } else {
        /*
         Added to create a new rating for this announcement on StackMob.  This rating
         will then be viewable on the view shown from clicking My Ratings.
         */
        [self createNewRatingForPlace:self.selectedPlace.name meal:self.selectedMeal rating:self.selectedRating comment:self.ratingComment];
    }
    
}

- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal
{
    // This URL is specific to this sample, and can be used to
    // create arbitrary OG objects for this app; your OG objects
    // will have URLs hosted by your server.
    /*
    NSString *format =
    @"https://<YOUR_BACK_END>/repeater.php?"
    @"fb:app_id=<YOUR_APP_ID>&og:type=%@&"
    @"og:title=%@&og:description=%%22%@%%22&"
    @"og:image=https://s-static.ak.fbcdn.net/images/devsite/attachment_blank.png&"
    @"body=%@";
    */
    // We create an FBGraphObject object, but we can treat it as
    // an SCOGMeal with typed properties, etc. See <FacebookSDK/FBGraphObject.h>
    // for more details.
    id<SCOGMeal> result = (id<SCOGMeal>)[FBGraphObject graphObject];
    
    // Give it a URL that will echo back the name of the meal as its title,
    // description, and body.
    
    // Only Pizza for now
    result.url = [NSString stringWithFormat:@"http://scrumptious.stackmob.stackmobapp.com/%@.html", [self.selectedMeal lowercaseString]];
    
    //result.url = [NSString stringWithFormat:format, @"stackmob-scrumptious:meal", meal, meal, meal];
    
    // Add comment and rating
    
    [result setObject:self.ratingComment forKey:@"comment"];
    [result setObject:[NSNumber numberWithInt:self.selectedRating] forKey:@"rating"];
    
    return result;
}

- (void)postPhotoThenOpenGraphAction
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    // First request uploads the photo.
    FBRequest *request1 = [FBRequest
                           requestForUploadPhoto:self.selectedPhoto];
    [connection addRequest:request1
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error) {
         }
     }
            batchEntryName:@"photopost"
     ];
    
    // Second request retrieves photo information for just-created
    // photo so we can grab its source.
    FBRequest *request2 = [FBRequest
                           requestForGraphPath:@"{result=photopost:$.id}"];
    [connection addRequest:request2
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error &&
             result) {
             NSString *source = [result objectForKey:@"source"];
             [self postOpenGraphActionWithPhotoURL:source];
         }
     }
     ];
    
    [connection start];
}

- (void)postOpenGraphActionWithPhotoURL:(NSString*)photoURL
{
    // First create the Open Graph meal object for the meal we ate.
    id<SCOGMeal> mealObject = [self mealObjectForMeal:self.selectedMeal];
    
    // Now create an Open Graph eat action with the meal, our location,
    // and the people we were with.
    id<SCOGEatMealAction> action =
    (id<SCOGEatMealAction>)[FBGraphObject graphObject];
    action.meal = mealObject;
    if (self.selectedPlace) {
        action.place = self.selectedPlace;
    }
    if (self.selectedFriends.count > 0) {
        action.tags = self.selectedFriends;
    }
    
    
    if (photoURL) {
        NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
        [image setObject:photoURL forKey:@"url"];
        
        NSMutableArray *images = [[NSMutableArray alloc] init];
        [images addObject:image];
        
        action.image = images;
    }
    
    // Create the request and post the action to the
    // "me/<YOUR_APP_NAMESPACE>:eat" path.
    [FBRequestConnection startForPostWithGraphPath:@"me/stackmob-scrumptious:eat"
                                       graphObject:action
                                 completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         [self.spinner stopAnimating];
         NSString *alertText;
         NSString *title;
         if (!error) {
             title = @"Successfully announced!";
             alertText = @"Go view the post in your Activity Log.";
             
         } else {
             title = @"Error!";
             alertText = @"Announcement not posted.  Please try again.";
             
         }
         [[[UIAlertView alloc] initWithTitle:title
                                     message:alertText
                                    delegate:nil
                           cancelButtonTitle:@"Thanks!"
                           otherButtonTitles:nil]
          show];
         [self resetMenu];
     }];
}

# pragma mark - Rating on StackMob
/*
 We create a new rating by instantiating a new Rating managed object using Core Data,
 populating it with information from the announcement,
 and calling the StackMob-provided asynchronous save method.
 The rating object is then translated and sent as a network request to StackMob,
 where it is saved to the servers.
 */
- (void)createNewRatingForPlace:(NSString *)place meal:(NSString *)meal rating:(int)rating comment:(NSString *)comment
{
    NSManagedObjectContext *context = [[self.appDelegate coreDataStore] contextForCurrentThread];
    Rating *newRating = [NSEntityDescription insertNewObjectForEntityForName:@"Rating" inManagedObjectContext:context];
    [newRating setRatingId:[newRating assignObjectId]];
    [newRating setPlace:place];
    [newRating setRating:[NSNumber numberWithInt:rating]];
    [newRating setMeal:meal];
    [newRating setComment:comment];
    
    // Create the NSData representation of the UIImage object sent as an argument.
    NSData *imageData = UIImageJPEGRepresentation(self.selectedPhoto, 0.7);
    
    // Convert the binary data to string to save on Amazon S3
    NSString *picData = [SMBinaryDataConversion stringForBinaryData:imageData name:@"image.jpg" contentType:@"image/jpg"];
    
    [newRating setPhoto:picData];
    
    [context saveOnSuccess:^{
        NSLog(@"Created new rating for %@", place);
       [context refreshObject:newRating mergeChanges:YES];
        
        [self postOpenGraphActionWithPhotoURL:newRating.photo];
        
    } onFailure:^(NSError *error) {
        NSLog(@"Error creating rating: %@", error);
        
        NSString *alertText = @"Error!";
        NSString *title = @"Announcement not posted.  Please try again.";
        
        [[[UIAlertView alloc] initWithTitle:title
                                    message:alertText
                                   delegate:nil
                          cancelButtonTitle:@"Thanks!"
                          otherButtonTitles:nil]
         show];
        [self resetMenu];

    }];
}

# pragma mark - Table View Methods

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView
                                               dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.textLabel.clipsToBounds = YES;
        
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.4
                                                         green:0.6
                                                          blue:0.8
                                                         alpha:1];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.detailTextLabel.clipsToBounds = YES;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"What are you eating?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"action-eating.png"];
            break;
            
        case 1:
            cell.textLabel.text = @"Where are you?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"action-location.png"];
            break;
            
        case 2:
            cell.textLabel.text = @"With whom?";
            cell.detailTextLabel.text = @"Select friends";
            cell.imageView.image = [UIImage imageNamed:@"action-people.png"];
            break;
            
        case 3:
            cell.textLabel.text = @"Got a picture?";
            cell.detailTextLabel.text = @"Take one";
            cell.imageView.image = [UIImage imageNamed:@"action-photo.png"];
            break;
        // Added for Rating feature
        case 4:
            cell.textLabel.text = @"Got a rating?";
            cell.detailTextLabel.text = @"Set one";
            cell.imageView.image = [UIImage imageNamed:@"action-photo.png"];
            break;
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Updated from 4 to 5 for Rating feature
    return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            if (!self.mealViewController) {
                __block SCViewController* myself = self;
                self.mealViewController = [[SCMealViewController alloc]
                                           initWithNibName:@"SCMealViewController" bundle:nil];
                self.mealViewController.selectItemCallback =
                ^(id sender, id selectedItem) {
                    myself.selectedMeal = selectedItem;
                    [myself updateSelections];
                };
            }
            [self.navigationController
             pushViewController:self.mealViewController
             animated:true];
            break;
        case 1:
            if (!self.placePickerController) {
                self.placePickerController = [[FBPlacePickerViewController alloc]
                                              initWithNibName:nil bundle:nil];
                self.placePickerController.delegate = self;
                self.placePickerController.title = @"Select a restaurant";
            }
            self.placePickerController.locationCoordinate =
            self.locationManager.location.coordinate;
            self.placePickerController.radiusInMeters = 1000;
            self.placePickerController.resultsLimit = 50;
            self.placePickerController.searchText = @"restaurant";
            
            [self.placePickerController loadData];
            [self.navigationController pushViewController:self.placePickerController
                                                 animated:true];
            break;
        case 2:
            if (!self.friendPickerController) {
                self.friendPickerController = [[FBFriendPickerViewController alloc]
                                               initWithNibName:nil bundle:nil];
                
                // Set the friend picker delegate
                self.friendPickerController.delegate = self;
                
                self.friendPickerController.title = @"Select friends";
            }
            
            [self.friendPickerController loadData];
            [self.navigationController pushViewController:self.friendPickerController
                                                 animated:true];
            break;
        case 3:
            if (!self.imagePicker) {
                self.imagePicker = [[UIImagePickerController alloc] init];
                self.imagePicker.delegate = self;
                
                // In a real app, we would probably let the user
                // either pick an image or take one using the camera.
                // For sample purposes in the simulator, the camera is not available.
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                // Can't use presentModalViewController for image picker on iPad
                if (!self.popover) {
                    self.popover = [[UIPopoverController alloc]
                                    initWithContentViewController:self.imagePicker];
                }
                CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
                [self.popover
                 presentPopoverFromRect:rect
                 inView:self.view
                 permittedArrowDirections:UIPopoverArrowDirectionAny
                 animated:YES];
            } else {
                [self presentModalViewController:self.imagePicker 
                                        animated:true];
            }
            break;
        // Added for Rating Feature
        case 4:
            if (!self.rateViewController) {
                __block SCViewController* myself = self;
                self.rateViewController = [[SCRateViewController alloc]
                                           initWithNibName:@"SCRateViewController" bundle:nil];
                self.rateViewController.selectRatingCallback =
                ^(id sender, int selectedRating, NSString *comment) {
                    myself.selectedRating = selectedRating;
                    myself.ratingComment = comment;
                    [myself updateSelections];
                };
            }
            [self.navigationController pushViewController:self.rateViewController
                                    animated:true];
            break;
    }
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - FBImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    self.selectedPhoto = image;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:true];
    }
    
    [self updateSelections];
}

# pragma mark - FBFriendPickerDelegate

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    self.selectedFriends = friendPicker.selection;
    [self updateSelections];
}

# pragma mark - FBPlacePickerDelegate

- (void)placePickerViewControllerSelectionDidChange:
(FBPlacePickerViewController *)placePicker
{
    self.selectedPlace = placePicker.selection;
    [self updateSelections];
    if (self.selectedPlace.count > 0) {
        [self.navigationController popViewControllerAnimated:true];
    }
}

# pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (!oldLocation ||
        (oldLocation.coordinate.latitude != newLocation.coordinate.latitude &&
         oldLocation.coordinate.longitude != newLocation.coordinate.longitude)) {
            
            // To-do, add code for triggering view controller update
            /*
            NSLog(@"Got location: %f, %f",
                  newLocation.coordinate.latitude,
                  newLocation.coordinate.longitude);
             */
        }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}

# pragma mark - Table View Cell Helpers

- (void)updateCellIndex:(int)index withSubtitle:(NSString*)subtitle {
    UITableViewCell *cell = (UITableViewCell *)[self.menuTableView
                                                cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.detailTextLabel.text = subtitle;
}

- (void)updateSelections
{
    
    NSString* friendsSubtitle = @"Select friends";
    int friendCount = self.selectedFriends.count;
    if (friendCount > 2) {
        // Just to mix things up, don't always show the first friend.
        id<FBGraphUser> randomFriend =
        [self.selectedFriends objectAtIndex:arc4random() % friendCount];
        friendsSubtitle = [NSString stringWithFormat:@"%@ and %d others",
                           randomFriend.name,
                           friendCount - 1];
    } else if (friendCount == 2) {
        id<FBGraphUser> friend1 = [self.selectedFriends objectAtIndex:0];
        id<FBGraphUser> friend2 = [self.selectedFriends objectAtIndex:1];
        friendsSubtitle = [NSString stringWithFormat:@"%@ and %@",
                           friend1.name,
                           friend2.name];
    } else if (friendCount == 1) {
        id<FBGraphUser> friend = [self.selectedFriends objectAtIndex:0];
        friendsSubtitle = friend.name;
    }
    
    [self updateCellIndex:3 withSubtitle:(self.selectedPhoto ? @"Ready" : @"Take one")];
    
    [self updateCellIndex:2 withSubtitle:friendsSubtitle];
    
    [self updateCellIndex:1 withSubtitle:(self.selectedPlace ?
                                          self.selectedPlace.name :
                                          @"Select One")];
    
    [self updateCellIndex:0 withSubtitle:(self.selectedMeal ?
                                          self.selectedMeal :
                                          @"Select One")];
    
    // Added for Rating feature
    [self updateCellIndex:4 withSubtitle:(self.selectedRating ?
                                          [NSString stringWithFormat:@"You gave it a %d out of 5", self.selectedRating] :
                                          @"Select One")];
    
    self.announceButton.enabled = (self.selectedMeal != nil);
    
}

#pragma mark - dealloc

- (void)dealloc
{
    _friendPickerController.delegate = nil;
    _locationManager.delegate = nil;
    self.placePickerController = nil;
    _placePickerController.delegate = nil;
    _imagePicker.delegate = nil;
}

@end
