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
#import "VYBPlayerControlViewController.h"
#import "VYBProfileViewController.h"
#import "VYBAppDelegate.h"
#import "VYBActivityInfoView.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) UIBarButtonItem *profileButton;
@property (nonatomic, strong) VYBActivityInfoView *activityInfo;
@end

@implementation VYBActivityTableViewController

@synthesize user = _user;

- (PFObject *)user {
    if (!_user) {
        _user = [PFUser currentUser];
    }
    return _user;
}

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
    
    //To remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self loadActivityInfoView];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    // Check notification permission settings
    if ([[[UIApplication sharedApplication] currentUserNotificationSettings] types] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsNotificationPermissionGrantedKey forKey:kVYBUserDefaultsNotificationPermissionKey];
    }
    NSString *notiPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsNotificationPermissionKey];
    if ( [notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionUndeterminedKey] ) {
        
        // iOS8
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Push Notification"
                                                                                     message:@"We would like to notify when there are live happenings around you" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                                                                                 UIUserNotificationTypeBadge |
                                                                                                                 UIUserNotificationTypeSound);
                                                                 UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                                                                          categories:nil];
                                                                 [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
                                                             }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            
            [self presentViewController:alertController animated:NO completion:nil];
        }
        /*
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Push Notification"
                                                                message:@"We would like to notify when there are live happenings around you"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        */

    }
    else if ([notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionDeniedKey]) {
        // iOS8
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enable Notification"
                                                                                     message:@"Please let us notify you so you know what's happening around you when you want from Settings -> Notifications"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *emptyAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:emptyAction];
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }


    [VYBUtility updateLastRefreshForCurrentUser];
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
            [self.activityInfo.profileImageView setImage:[VYBUtility maskImage:profileImg withMask:[UIImage imageNamed:@"thumbnail_mask"]]];
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
                cell.profilePic.image = [VYBUtility maskImage:[UIImage imageWithData:data]
                                                     withMask:[UIImage imageNamed:@"thumbnail_mask"]];
            }
        }];
    }
    PFFile *vybeThumbnail = object[kVYBActivityVybeKey][kVYBVybeThumbnailKey];
    if (vybeThumbnail) {
        [vybeThumbnail getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                cell.vybeThumbnail.image = [VYBUtility maskImage:[UIImage imageWithData:data]
                                                        withMask:[UIImage imageNamed:@"thumbnail_mask"]];
            }
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *selectedActivity = [self.objects objectAtIndex:indexPath.row];
    PFObject *selectedVybe = selectedActivity[kVYBActivityVybeKey];
    
    VYBPlayerControlViewController *playerController = [[VYBPlayerControlViewController alloc] initWithNibName:@"VYBPlayerControlViewController" bundle:nil];
    [playerController setVybePlaylist:@[selectedVybe]];
    [self presentViewController:playerController animated:NO completion:^{
        [playerController beginPlayingFrom:0];
    }];
}

- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

#pragma mark - UIAlertViewDelegate

// iOS7 and prior
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
