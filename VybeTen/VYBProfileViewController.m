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
    
    if ( [[PFUser currentUser].objectId isEqualToString:self.user.objectId] ) {
        self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
        self.navigationItem.rightBarButtonItem = self.actionButton;
    }
    
    self.profileInfo = [[[NSBundle mainBundle] loadNibNamed:@"VYBProfileInfoView" owner:nil options:nil] lastObject];
    self.tableView.tableHeaderView = self.profileInfo;
    self.profileInfo.delegate = self;
    
    self.profileInfo.usernameLabel.text = self.user[kVYBUserUsernameKey];
    self.navigationItem.title = self.user[kVYBUserUsernameKey];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeUserKey equalTo:self.user];
    NSDate *someTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    
    return query;
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    PFFile *thumbnailFile = self.user[kVYBUserProfilePicMediumKey];
    [thumbnailFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *profileImg = [UIImage imageWithData:data];
            [self.profileInfo.profileImageView setImage:profileImg];
        }
    }];
}

#pragma mark - UITableViewController 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *VybeTableViewCellIdentifier = @"VybeTableViewCellIdentifier";
    VYBVybeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VybeTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
    }
    
    cell.timestampLabel.text = [VYBUtility localizedDateStringFrom:object[kVYBVybeTimestampKey]];
    
    PFFile *thumbnailFile = object[kVYBVybeThumbnailKey];
    if (thumbnailFile) {
        [thumbnailFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *thumbImg = [UIImage imageWithData:data];
                [cell.thumbnailImageView setImage:thumbImg];
            }
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setVybePlaylist:self.objects];
    [playerVC setCurrVybeIndex:indexPath.row];
    [playerVC setCurrUser:self.user];
    [self.navigationController pushViewController:playerVC animated:NO];
}


- (void)actionButtonPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles:@"Choose a profile photo", nil];
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


- (void)watchAllButtonPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setVybePlaylist:self.objects];
    [playerVC setCurrVybeIndex:0];
    [playerVC setCurrUser:self.user];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
