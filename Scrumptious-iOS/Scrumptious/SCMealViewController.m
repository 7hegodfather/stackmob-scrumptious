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

#import "SCMealViewController.h"

@implementation SCMealViewController
@synthesize selectItemCallback = _selectItemCallback;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Select a meal";
        
        NSArray *arrayOfMeals = [NSArray arrayWithObjects:
                  @"Pizza",
                  @"Chinese",
                  @"French",
                  @"Hamburger",
                  @"Hotdog",
                  @"Indian",
                  @"Italian",
                  @"Thai", nil];
        
        _meals = [arrayOfMeals sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    return self;
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

# pragma mark - Table View Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _meals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [self.tableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [_meals objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"action-eating.png"];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectItemCallback) {
        self.selectItemCallback(self, [_meals objectAtIndex:indexPath.row]);
    }
    [self.navigationController popViewControllerAnimated:true];
}

@end
