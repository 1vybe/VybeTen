//
//  VYBActivityTableViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBActivityTableViewController.h"
#import "VYBVybeTableViewCell.h"

#import "VYBAppDelegate.h"

#import "VYBUtility.h"
#import "VYBCache.h"

#import "VYBPlayerControlViewController.h"

#import "VYBLogInViewController.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *vybeCountLabel;

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation VYBActivityTableViewController

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.parseClassName = kVYBVybeClassKey;
        self.paginationEnabled = YES;
        self.pullToRefreshEnabled = YES;
        self.objectsPerPage = 25;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usernameLabel.text = [PFUser currentUser].username;
    
    // Remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self getPermissionIfNeeded];

    [VYBUtility updateLastRefreshForCurrentUser];
}

#pragma mark - UIView

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - IBActions

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles:nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Private

- (void)getPermissionIfNeeded {
    
    // iOS8
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // Check notification permission settings
        if ([[[UIApplication sharedApplication] currentUserNotificationSettings] types] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsNotificationPermissionGrantedKey forKey:kVYBUserDefaultsNotificationPermissionKey];
        }
        
        NSString *notiPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsNotificationPermissionKey];
        if ( [notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionUndeterminedKey] ) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Push Notification"
                                                                                     message:@"We would like to notify when there are live happenings around you"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
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
        else if ([notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionDeniedKey]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enable Notification"
                                                                                     message:@"Please let us notify you so you know what's happening around you when you want from Settings -> Notifications"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *emptyAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:emptyAction];
            
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }
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

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kVYBVybeUserKey equalTo:[PFUser currentUser]];
    [query orderByDescending:kVYBVybeTimestampKey];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    self.vybeCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.objects.count];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    if (indexPath.row == self.objects.count) {
        // Load more was pressed
        return;
    }
    
    PFObject *selectedVybe = [self.objects objectAtIndex:indexPath.row];
    
    VYBPlayerControlViewController *playerController = [[VYBPlayerControlViewController alloc] initWithNibName:@"VYBPlayerControlViewController" bundle:nil];
    playerController.vybePlaylist = @[selectedVybe];
    
    [self presentViewController:playerController animated:NO completion:nil];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"VybeCell"];
    
    cell.locationLabel.text = [[object[kVYBVybeLocationStringKey] componentsSeparatedByString:@","] objectAtIndex:0];
    cell.timestampLabel.text = [VYBUtility reverseTime:object[kVYBVybeTimestampKey]];
    
    cell.thumbnailImageView.file = object[kVYBVybeThumbnailKey];
    [cell.thumbnailImageView loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            cell.thumbnailImageView.image = [VYBUtility maskImage:image withMask:[UIImage imageNamed:@"ThumbnailMask"]];
        }
    }];
    

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            NSLog(@"Logging out");
            [(VYBAppDelegate *)[UIApplication sharedApplication].delegate logOut];
            break;
    }
}

@end
