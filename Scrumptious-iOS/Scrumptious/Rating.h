//
//  Rating.h
//  Scrumptious
//
//  Created by Carl Atupem on 4/5/13.
//  Copyright (c) 2013 StackMob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Rating : NSManagedObject

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * meal;
@property (nonatomic, retain) NSString * place;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSString * ratingId;
@property (nonatomic, retain) NSString * photo;

@end
