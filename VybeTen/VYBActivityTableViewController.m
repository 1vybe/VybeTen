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

@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, weak) PFObject *user;

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
    
    [self setNavigationBarItems];

    // Remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.leftBarButtonItem = captureButton;
    
    if ([[PFUser currentUser].objectId isEqualToString:self.user.objectId]) {
        self.actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_settings.png"] style:UIBarButtonItemStylePlain target:self action:@selector(actionButtonPressed:)];
        
        self.navigationItem.rightBarButtonItem = self.actionButton;
    }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"VybeCell"];
    
    cell.locationLabel.text = [[object[kVYBVybeLocationStringKey] componentsSeparatedByString:@","] objectAtIndex:0];
    cell.timestampLabel.text = [VYBUtility localizedDateStringFrom:object[kVYBVybeTimestampKey]];
    
    PFFile *thumbnailFile = object[kVYBVybeThumbnailKey];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.objects count];
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
            [(VYBAppDelegate *)[UIApplication sharedApplication].delegate logOut];
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
