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

/*
 Controller for the Rate view.  Much of the logic for this
 view comes from the RateView class.
 */

#import "RateView.h"
#import "SCViewController.h"

@interface SCRateViewController : UIViewController <RateViewDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet RateView *rateView;

@property (strong, nonatomic) SelectRatingCallback selectRatingCallback;

@property (unsafe_unretained, nonatomic) IBOutlet UITextView *commentView;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end
