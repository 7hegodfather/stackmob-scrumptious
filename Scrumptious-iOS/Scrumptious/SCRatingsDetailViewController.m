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

#import "SCRatingsDetailViewController.h"
#import <SDWebImage/SDWebImageDownloader.h>

@implementation SCRatingsDetailViewController

@synthesize place = _place;
@synthesize meal = _meal;
@synthesize rating = _rating;
@synthesize comment = _comment;
@synthesize averageRating = _averageRating;
@synthesize photo = _photo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rating Detail";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.placeLabel.text = self.place;
    self.mealLabel.text = self.meal;
    self.ratingLabel.text = [NSString stringWithFormat:@"%@ out of 5", self.rating];
    self.averageRatingLabel.text = self.averageRating ? [NSString stringWithFormat:@"%@ out of 5", self.averageRating] : @"";
    self.commentTextView.text = self.comment;

    [self.imageView setImageWithURL:[NSURL URLWithString:self.photo]];
    
}

- (void)viewDidUnload {
    [self setMealLabel:nil];
    [self setRatingLabel:nil];
    [self setCommentTextView:nil];
    [self setAverageRatingLabel:nil];
    [self setPlaceLabel:nil];
    [self setImageView:nil];
    [super viewDidUnload];
}
@end
