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

#import "SCRateViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface SCRateViewController () {
    int currentRating;
}

@end

@implementation SCRateViewController

@synthesize scrollView = _scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Rate";
    self.rateView.notSelectedImage = [UIImage imageNamed:@"star_empty.png"];
    self.rateView.halfSelectedImage = [UIImage imageNamed:@"star_half.png"];
    self.rateView.fullSelectedImage = [UIImage imageNamed:@"star_full.png"];
    self.rateView.rating = 0;
    self.rateView.editable = YES;
    self.rateView.maxRating = 5;
    self.rateView.delegate = self;
    currentRating = 0;
    self.commentView.layer.borderWidth = 1.0f;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

- (void)viewDidUnload {
    [self setRateView:nil];
    [self setCommentView:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
}

- (void)rateView:(RateView *)rateView ratingDidChange:(float)rating {
    if ((int)rating != currentRating) {
        currentRating = (int)rating;
    }
}

- (void)doneButtonPressed:(id)sender
{
    if (self.selectRatingCallback) {
        self.selectRatingCallback(self, currentRating, self.commentView.text);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
