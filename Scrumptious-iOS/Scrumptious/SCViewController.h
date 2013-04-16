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

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

typedef void(^SelectItemCallback)(id sender, id selectedItem);
typedef void(^SelectRatingCallback)(id sender, int selectedRating, NSString *comment);

@interface SCViewController : UIViewController

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *userNameLabel;

@property (unsafe_unretained, nonatomic) IBOutlet FBProfilePictureView *userProfileImage;

@property (unsafe_unretained, nonatomic) IBOutlet UITableView *menuTableView;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *announceButton;

@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)announce:(id)sender;

@end
