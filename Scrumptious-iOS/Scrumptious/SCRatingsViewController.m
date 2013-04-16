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

#import "SCRatingsViewController.h"
#import "SCAppDelegate.h"
#import "StackMob.h"
#import "Rating.h"
#import "SCRatingsDetailViewController.h"


@interface SCRatingsViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    NSArray *_ratings;
    NSDictionary *_averageRatings;
}

@property (strong, nonatomic) SCRatingsDetailViewController *detailViewController;

@end

@implementation SCRatingsViewController

@synthesize detailViewController = _detailViewController;

- (SCAppDelegate *)appDelegate
{
    return (SCAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"My Ratings";
        _ratings = nil;
        _averageRatings = nil;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fetchRatings];
}


- (void)viewDidUnload {
    
    [self setTableView:nil];
    [super viewDidUnload];
}

/*
 Fetches the currently logged in user's ratings by
 creating a Core Data fetch request and executing it
 using the StackMob-provided asynchronous fetch method.
 The table data is reloaded upon successful fetch.
 */
- (void)fetchRatings {
    
    NSFetchRequest *ratingsFetch = [[NSFetchRequest alloc] initWithEntityName:@"Rating"];
    NSManagedObjectContext *context = [[self.appDelegate coreDataStore] contextForCurrentThread];
    [ratingsFetch setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"place" ascending:YES]]];
    
    [context executeFetchRequest:ratingsFetch onSuccess:^(NSArray *results) {
        _ratings = results;
        [[self tableView] reloadData];
        if ([results count] > 0) {
            [self getAverageRatings:results];
        }
    } onFailure:^(NSError *error) {
        NSLog(@"Error fetching ratings: %@", error);
    }];
    
}

/*
 Fires StackMob custom code request which returns average ratings for
 all user's ratings.
 */
- (void)getAverageRatings:(NSArray *)results
{
    // Create an array of all the names of the places
    __block NSMutableArray *placeNamesArray = [NSMutableArray arrayWithCapacity:[results count]];
    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *placeName = [obj valueForKey:@"place"];
        if (placeName) {
            [placeNamesArray addObject:placeName];
        }
    }];
    
    // Create body for Custom Code Request
    NSString *placesNames = [placeNamesArray componentsJoinedByString:@","];
    NSString *jsonString = [NSString stringWithFormat:@"{places:\"%@\"}", placesNames];
    
    // Create and perform the custom code request, passing the JSON string as the body
    SMCustomCodeRequest *avgRatingsRequest = [[SMCustomCodeRequest alloc] initPostRequestWithMethod:@"getAverageRating" body:jsonString];
    [[[self appDelegate] coreDataStore] performCustomCodeRequest:avgRatingsRequest onSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        _averageRatings = (NSDictionary *)JSON;
        
    } onFailure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"Error getting average ratings, %@", error);
    }];
}

# pragma mark - Table View Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _ratings ? [_ratings count] : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    
    
    UITableViewCell *cell = [[UITableViewCell alloc]
                                    initWithStyle:UITableViewCellStyleSubtitle
                                    reuseIdentifier:CellIdentifier];
    
    if (_ratings) {
        Rating *rating = [_ratings objectAtIndex:indexPath.row];
        NSString *placeName = [rating valueForKey:@"place"];
        cell.textLabel.text = placeName ? placeName : [rating valueForKey:@"meal"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([rating valueForKey:@"rating"]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Rated: %@", [rating valueForKey:@"rating"]];
        }
        
        
        if (rating.photo) {
            
            CGFloat x = cell.frame.size.height;
            cell.indentationLevel = 1;
            cell.indentationWidth = 40;
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, x, x)];
            [cell addSubview:imageView];
             
            [imageView setImageWithURL:[NSURL URLWithString:rating.photo]];
            
        }
        
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.detailViewController) {
        self.detailViewController = [[SCRatingsDetailViewController alloc]
                                   initWithNibName:@"SCRatingsDetailViewController" bundle:nil];
    }
    
    // Get rating managed object for row and assign values to detail view properties
    NSManagedObject *rating = [_ratings objectAtIndex:indexPath.row];
    NSString *place = [rating valueForKey:@"place"];
    self.detailViewController.place = place;
    self.detailViewController.meal = [rating valueForKey:@"meal"];
    self.detailViewController.rating = [rating valueForKey:@"rating"];
    self.detailViewController.comment = [rating valueForKey:@"comment"];
    self.detailViewController.averageRating = place ? [_averageRatings objectForKey:place] : nil;
    self.detailViewController.photo = [rating valueForKey:@"photo"];
    
    [self.navigationController
     pushViewController:self.detailViewController
     animated:true];
}



@end
