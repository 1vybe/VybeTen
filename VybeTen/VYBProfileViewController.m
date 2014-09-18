//
//  VYBProfileViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBProfileViewController.h"
#import "VYBVybeTableViewCell.h"
#import "VYBProfileInfoView.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBLogInViewController.h"
#import "VYBPlayerViewController.h"

@interface VYBProfileViewController ()
@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) VYBProfileInfoView *profileInfo;
@end

@implementation VYBProfileViewController

@synthesize user = _user;

-(PFObject *)user {
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
    
    // Remove border line
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    
    [self setNavigationBarItems];
    [self loadProfileInfoView];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

-(void)setNavigationBarItems {
    self.navigationItem.title = self.user[kVYBUserUsernameKey];
    if ([[PFUser currentUser].objectId isEqualToString:self.user.objectId]) {
//        self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
//                                                                          target:self
//                                                                          action:@selector(actionButtonPressed:)];
        self.actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_settings.png"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(actionButtonPressed:)];

        self.navigationItem.rightBarButtonItem = self.actionButton;
    }
}

-(void)loadProfileInfoView {
    self.profileInfo = [[[NSBundle mainBundle] loadNibNamed:@"VYBProfileInfoView" owner:nil options:nil] lastObject];
    self.profileInfo.delegate = self;
    [self loadProfileImage];
    
    PFQuery *countQuery = [PFQuery queryWithClassName:@"_User"];
    [countQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            if (number > 0) {
                NSLog(@"Success!");
                self.profileInfo.followersLabel.text = [NSString stringWithFormat:@"%d", number];
                self.profileInfo.followingLabel.text = [NSString stringWithFormat:@"%d", number];
            }
        } else {
            NSLog(@"Error fetching User count: %@", error);
        }
    }];
    
    self.tableView.tableHeaderView = self.profileInfo;
}

-(void)loadProfileImage {
    PFFile *thumbnailFile = self.user[kVYBUserProfilePicMediumKey];
    [thumbnailFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *profileImg = [UIImage imageWithData:data];
            UIImage *maskImg = [UIImage imageNamed:@"thumbnail_mask"];
            [self.profileInfo.profileImageView setImage:[VYBUtility maskImage:profileImg withMask:maskImg]];
        }
    }];
}

#pragma mark - VYBProfileInfoView

- (void)watchAllButtonPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
    [playerVC setVybePlaylist:[self.objects.reverseObjectEnumerator allObjects]];
    [playerVC setCurrVybeIndex:0];
    [playerVC setCurrUser:self.user];
    [self presentViewController:playerVC animated:NO completion:nil];
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
            [self presentViewController:loginVC animated:NO completion:nil];
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

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeUserKey equalTo:self.user];
    NSDate *someTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    [query orderByDescending:kVYBVybeTimestampKey];
    
    return query;
}

#pragma mark - UITableViewController

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *VybeTableViewCellIdentifier = @"VybeTableViewCellIdentifier";
    VYBVybeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VybeTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
    }
    
    cell.timestampLabel.text = [VYBUtility localizedDateStringFrom:object[kVYBVybeTimestampKey]];
    NSString *location = object[kVYBVybeLocationStringKey];
    NSArray *locationComponents = [location componentsSeparatedByString:@","];
    cell.locationLabel.text = [locationComponents objectAtIndex:0];
    
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
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
    [playerVC setVybePlaylist:[[self.objects reverseObjectEnumerator] allObjects]];
    [playerVC setCurrVybeIndex:self.objects.count - indexPath.row - 1];
    [playerVC setCurrUser:self.user];
    [self presentViewController:playerVC animated:NO completion:nil];
}

// Use this to test out likes
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [VYBUtility likeVybeInBackground:(PFObject *)[self.objects objectAtIndex:indexPath.row] block:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            NSLog(@"You liked that vybe.");
//        } else {
//            NSLog(@"%@", error);
//        }
//    }];
//}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
