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
#import "VYBAppDelegate.h"
#import "VYBActivityInfoView.h"

#import "VYBVybeTableViewCell.h"
#import "VYBCache.h"
#import "VYBLogInViewController.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) UIBarButtonItem *actionButton;
@property (weak, nonatomic) VYBActivityInfoView *activityInfo;
@property (weak, nonatomic) PFObject *user;

- (void)setNavigationBarItems;
- (void)captureButtonPressed:(id)sender;

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
    
    // Remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self loadActivityInfoView];

    [self setNavigationBarItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNavigationBarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // iOS8
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // Check notification permission settings
        if ([[[UIApplication sharedApplication] currentUserNotificationSettings] types] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsNotificationPermissionGrantedKey forKey:kVYBUserDefaultsNotificationPermissionKey];
        }
        
        NSString *notiPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsNotificationPermissionKey];
        if ( [notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionUndeterminedKey] ) {
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

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Accessors

- (PFObject *)user {
    if (!_user) {
        _user = [PFUser currentUser];
    }
    return _user;
}

#pragma mark - Private

- (void)setNavigationBarItems {
    self.navigationItem.title = @"ACTIVITY";
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.leftBarButtonItem = captureButton;
    
    if ([[PFUser currentUser].objectId isEqualToString:self.user.objectId]) {
        self.actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_settings.png"] style:UIBarButtonItemStylePlain target:self action:@selector(actionButtonPressed:)];
        
        self.navigationItem.rightBarButtonItem = self.actionButton;
    }
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
            UIImage *profileImage = [UIImage imageWithData:data];
            UIImage *profileMask = [UIImage imageNamed:@"thumbnail_mask"];
            [self.activityInfo.profileImageView setImage:[VYBUtility maskImage:profileImage withMask:profileMask]];
        }
    }];
}

- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

#pragma mark - UIView

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    NSString *location = object[kVYBVybeLocationStringKey];
    PFFile *thumbnailFile = object[kVYBVybeThumbnailKey];
    
    VYBVybeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VybeTableViewCellIdentifier"];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"VYBVybeTableViewCell" owner:nil options:nil] lastObject];
    }
    cell.locationLabel.text = [[location componentsSeparatedByString:@","] objectAtIndex:0];
    cell.timestampLabel.text = [VYBUtility localizedDateStringFrom:object[kVYBVybeTimestampKey]];

    if (thumbnailFile) {
        [thumbnailFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                cell.thumbnailImageView.image = [VYBUtility maskImage:[UIImage imageWithData:data]
                                                             withMask:[UIImage imageNamed:@"thumbnail_mask"]];
            }
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *selectedVybe = [self.objects objectAtIndex:indexPath.row];
    
    VYBPlayerControlViewController *playerController = [[VYBPlayerControlViewController alloc] initWithNibName:@"VYBPlayerControlViewController" bundle:nil];
    [playerController setVybePlaylist:@[selectedVybe]];
    [self presentViewController:playerController animated:NO completion:^{
        [playerController beginPlayingFrom:0];
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    assert(self.user != nil);
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeUserKey equalTo:self.user];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:[NSDate dateWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS]];
    [query orderByDescending:kVYBVybeTimestampKey];
    
    return query;
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

#pragma mark - UIActionSheetDelegate

- (void)actionButtonPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Logout"
                                                    otherButtonTitles:@"Choose a profile photo", nil];
    [actionSheet showFromBarButtonItem:self.actionButton animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self chooseProfilePhoto];
            break;
        case 0:
            NSLog(@"Logging out");
            // clear cache
            [[VYBCache sharedCache] clear];
            
            // Unsubscribe from push notifications by removing the user association from the current installation.
            [[PFInstallation currentInstallation] removeObjectForKey:@"user"];
            [[PFInstallation currentInstallation] saveInBackground];
            
            // Clear all caches
            [PFQuery clearAllCachedResults];
            
            [PFUser logOut];
            
            VYBLogInViewController *loginVC = [[VYBLogInViewController alloc] init];
            [self.navigationController pushViewController:loginVC animated:NO];
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)chooseProfilePhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    NSData *data = UIImagePNGRepresentation(chosenImage);
    PFFile *thumbnailFile = [PFFile fileWithData:data];
    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [[PFUser currentUser] setObject:thumbnailFile forKey:kVYBUserProfilePicMediumKey];
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Success"];
                } else {
                    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_x.png"] title:@"Failed"];
                }
            }];
        } else {
            [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_x.png"] title:@"Failed"];
        }
    }];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
