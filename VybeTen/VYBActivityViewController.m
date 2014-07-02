//
//  VYBActivityViewController.m
//  VybeTen
//
//  Created by jinsuk on 5/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBActivityViewController.h"

@interface VYBActivityViewController ()
@property (nonatomic, strong) NSDate *lastRefresh;
@end

@implementation VYBActivityViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.paginationEnabled = NO;
        
        self.pullToRefreshEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsActivityLastRefreshKey];
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBTribeClassKey];

    if (![PFUser currentUser]) {
        [query setLimit:0];
        return query;
    }
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [followingQuery whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
    [followingQuery whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    
    PFQuery *createdQuery = [PFQuery queryWithClassName:kVYBTribeClassKey];
    [createdQuery whereKey:kVYBTribeCreatorKey matchesKey:kVYBActivityToUserKey inQuery:followingQuery];
    [createdQuery whereKey:kVYBTribeTypeKey equalTo:kVYBTribeTypePublic];
    [createdQuery includeKey:kVYBTribeCreatorKey];
    //[createdQuery orderByDescending:@"createdAt"];
    
    PFQuery *tribesQuery = [PFQuery queryWithClassName:kVYBTribeClassKey];
    [tribesQuery whereKey:kVYBTribeMembersKey equalTo:[PFUser currentUser]];

    PFQuery *vybeQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [vybeQuery whereKey:kVYBVybeTribeKey matchesQuery:tribesQuery];
    [vybeQuery includeKey:kVYBVybeTribeKey];
    [vybeQuery includeKey:kVYBVybeUserKey];
    [vybeQuery orderByDescending:@"createdAt"];
    
    return vybeQuery;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
}

#pragma mark - UITableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *ActivityCellIdentifier = @"ActivityCellIdentifier";
    
    VYBActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:ActivityCellIdentifier];
    if (!cell) {
        cell = [[VYBActivityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActivityCellIdentifier];
        cell.delegate = self;
    }
    
    [cell setActivity:object];
    
    return cell;
}

#pragma mark - VYBActivityCellDelegate

- (void)cell:(VYBActivityCell *)cell didTapTribeButton:(PFObject *)aActivity {
    
}

#pragma mark - ()

+ (NSString *)stringForActivity:(PFObject *)aActivity {
    
    if ([aActivity.parseClassName isEqualToString:kVYBActivityClassKey]) {
        if ([[aActivity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeFollow]) {
            return @" started following you";
        } else if ([[aActivity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeJoined]) {
            return @" joined Vybe";
        }
    } else if ([aActivity.parseClassName isEqualToString:kVYBTribeClassKey]) {
        if ([[aActivity objectForKey:kVYBTribeTypeKey] isEqualToString:kVYBTribeTypePublic]) {
            return @" created ";
        } else if ([[aActivity objectForKey:kVYBTribeTypeKey] isEqualToString:kVYBTribeTypePrivate]) {
            return @" added you to ";
        }
    } else if ([aActivity.parseClassName isEqualToString:kVYBVybeClassKey]) {
        return @" vybed in ";
    }
    
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
