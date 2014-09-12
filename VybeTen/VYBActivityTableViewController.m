//
//  VYBActivityTableViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBActivityTableViewController.h"
#import "VYBActivityTableViewCell.h"
#import "VYBUtility.h"
#import "VYBPlayerViewController.h"
#import "VYBProfileViewController.h"
#import "VYBAppDelegate.h"
#import "VYBActivityInfoView.h"

@interface VYBActivityTableViewController ()
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) VYBActivityInfoView *activityInfo;
@end

@implementation VYBActivityTableViewController

#pragma mark - Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadActivityInfoView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setNavigationBarItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Private

- (void)setNavigationBarItems {
    self.navigationItem.title = @"ACTIVITY";
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(captureButtonPressed:)];
    self.navigationItem.leftBarButtonItem = captureButton;
    
}

- (void)profileButtonPressed:(id)sender {
    VYBProfileViewController *profileVC = [[VYBProfileViewController alloc] init];
    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)loadActivityInfoView {
    self.activityInfo = [[[NSBundle mainBundle] loadNibNamed:@"VYBActivityInfoView" owner:self options:nil] lastObject];
    self.activityInfo.delegate = self;
    self.activityInfo.usernameLabel.text = self.user[kVYBUserUsernameKey];
    self.activityInfo.locationLabel.text = self.user[kVYBUserLastVybedLocationKey];
    [self loadProfileImage];
    self.tableView.tableHeaderView = self.activityInfo;
}

- (void)loadProfileImage {
    PFFile *thumbnailFile = self.user[kVYBUserProfilePicMediumKey];
    [thumbnailFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *profileImg = [UIImage imageWithData:data];
            [self.activityInfo.profileImageView setImage:profileImg];
        }
    }];
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [query whereKey:kVYBActivityToUserKey equalTo:self.user];
    NSDate *someTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:@"createdAt" greaterThanOrEqualTo:someTimeAgo];
    [query orderByDescending:@"createdAt"];
    [query includeKey:kVYBActivityFromUserKey];
    [query includeKey:kVYBActivityVybeKey];
    
    return query;
}

#pragma mark - UITableViewController 

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *ActivityTableViewCellIdentifier = @"ActivityTableViewCellIdentifier";
    VYBActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ActivityTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBActivityTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
    }

    cell.username.text = object[kVYBActivityFromUserKey][kVYBUserUsernameKey];
    
    if ([object[kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
        cell.activity.text = @"Likes your Vybe";
    } else {
        cell.activity.text = object[kVYBActivityTypeKey];
    }
    
    PFFile *profilePic = object[kVYBActivityFromUserKey][kVYBUserProfilePicMediumKey];
    if (profilePic) {
        [profilePic getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                cell.profilePic.image = [UIImage imageWithData:data];
            }
        }];
    }
    PFFile *vybeThumbnail = object[kVYBActivityVybeKey][kVYBVybeThumbnailKey];
    if (vybeThumbnail) {
        [vybeThumbnail getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                cell.vybeThumbnail.image = [UIImage imageWithData:data];
            }
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *selectedActivity = [self.objects objectAtIndex:indexPath.row];
    PFObject *selectedVybe = selectedActivity[kVYBActivityVybeKey];
    
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
    [playerVC setVybePlaylist:@[selectedVybe]];
    [self presentViewController:playerVC animated:NO completion:nil];
}

- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
