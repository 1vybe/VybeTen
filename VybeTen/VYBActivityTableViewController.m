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

#import "VYBPlayerViewController.h"

#import "VYBLogInViewController.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate, VYBPlayerViewControllerDelegate, VYBVybeTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (nonatomic) NSArray *activeLocations;
@property (nonatomic) NSArray *myLocations;
@property (retain, nonatomic) NSMutableDictionary *sectionToZoneNameMap;

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender;


@end

@implementation VYBActivityTableViewController {
  
    NSInteger _selectedSection;

    NSInteger _numOfActiveZones;
}

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.parseClassName = kVYBVybeClassKey;
    self.paginationEnabled = NO;
    self.pullToRefreshEnabled = YES;
    self.objectsPerPage = 500;
    self.activeLocations = [NSArray array];
    self.myLocations = [NSArray array];
    self.sectionToZoneNameMap = [NSMutableDictionary dictionary];
  }
  
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usernameLabel.text = [PFUser currentUser].username;
    
    // Remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.delegate = self;
    
    _selectedSection = -1;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName
           value:@"Activity Screen"];
        
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
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

- (NSString *)zoneForSection:(NSInteger)section {
    return [self.sectionToZoneNameMap objectForKey:[NSNumber numberWithInteger:section]];
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
    [query orderByDescending:kVYBVybeZoneNameKey];
    [query addDescendingOrder:kVYBVybeTimestampKey];
    query.limit = 500;
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    [[ZoneStore sharedInstance] didFetchUnlockedVybes:self.objects completionHandler:^(BOOL success) {
        if (success) {
            self.activeLocations = [[ZoneStore sharedInstance] activeUnlockedZones];
            self.myLocations = [[ZoneStore sharedInstance] unlockedZones];
          
            NSString *locationCntText = (self.myLocations.count > 1) ? [NSString stringWithFormat:@"%d Locations", (int)self.myLocations.count] : [NSString stringWithFormat:@"%d Location", (int)self.myLocations.count];
            NSString *vybeCntText = (self.objects.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)self.objects.count] : [NSString stringWithFormat:@"%d Vybe", (int)self.objects.count];

            self.countLabel.text = [NSString stringWithFormat:@"%@ - %@", locationCntText, vybeCntText];
            
            [self.tableView reloadData];
        }
    }];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
//  if (indexPath.section == 1) {
//    //TODO: This needs to change
//    Zone *zone = self.myLocations[indexPath.row];
//    PFObject *vybe = [zone.myVybes objectAtIndex:indexPath.row];
//    
//    return vybe;
//  }
//    
  return nil;
}



#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 36.0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActiveLocationTitleView"];
    return cell;
  }
    
  else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyLocationTitleView"];
    return cell;
  }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return self.activeLocations.count;
  }
  
  if (section == 1) {
    //TODO: This should change
    return self.myLocations.count;
  }
  
  return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 85.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
  NSInteger section = indexPath.section;
  
  // Active Location Cell
  if (section == 0) {
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    cell.delegate = self;
    //cell.tag = section;
    
    Zone *zone = self.activeLocations[indexPath.row];
    cell.locationLabel.text = zone.name;
    
    PFObject *lastVybe = zone.mostRecentVybe;
    NSDate *timestampDate = zone.mostRecentActiveVybeTimestamp;
    
    // FRESH vybes
    NSArray *freshContents = [[ZoneStore sharedInstance] freshVybesFromZone:zone.zoneID];
    if (freshContents && freshContents.count) {
      lastVybe = zone.freshContents.lastObject;
      timestampDate = lastVybe[kVYBVybeTimestampKey];
      cell.timestampLabel.textColor = [UIColor whiteColor];
      cell.locationLabel.textColor = [UIColor whiteColor];
      cell.listBarImageView.image = [UIImage imageNamed:@"BlueCell.png"];
      NSString *vybeCntText = (freshContents.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)freshContents.count] : [NSString stringWithFormat:@"%d Vybe", (int)freshContents.count];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
    }
    else {
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@", [VYBUtility reverseTime:timestampDate]];
    }
    
    cell.thumbnailImageView.hidden = NO;
    cell.thumbnailImageView.file = lastVybe[kVYBVybeThumbnailKey];
    
    [cell.thumbnailImageView loadInBackground:^(UIImage *image, NSError *error) {
      if (!error) {
        if (image) {
          UIImage *maskImage;
          if (image.size.height > image.size.width) {
            maskImage = [UIImage imageNamed:@"thumbnail_mask_portrait"];
          } else {
            maskImage = [UIImage imageNamed:@"thumbnail_mask_landscape"];
          }
          cell.thumbnailImageView.image = [VYBUtility maskImage:image withMask:maskImage];
        } else {
          cell.thumbnailImageView.image = [UIImage imageNamed:@"Oval_mask"];
        }
      }
    }];
    
    return cell;
  }
  // My Location Cell
  else {
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    cell.delegate = self;
    //cell.tag = section;
    
    Zone *zone = self.myLocations[indexPath.row];
    cell.locationLabel.text = zone.name;
    
    PFObject *lastVybe = zone.myVybes.firstObject;
    NSDate *timestampDate = lastVybe[kVYBVybeTimestampKey];
    
    NSString *vybeCntText = (zone.myVybes.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)zone.myVybes.count] : [NSString stringWithFormat:@"%d Vybe", (int)zone.myVybes.count];
    cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - Last Vybe taken %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
    cell.thumbnailImageView.hidden = YES;
    
    return cell;
  }
  
  /*
   VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"VybeCell"];
   
   NSDate *timestampDate = object[kVYBVybeTimestampKey];
   cell.timestampLabel.text = [NSString stringWithFormat:@"%@  (%@)", [VYBUtility localizedDateStringFrom:timestampDate], [VYBUtility reverseTime:timestampDate]];
   
   cell.thumbnailImageView.file = object[kVYBVybeThumbnailKey];
   [cell.thumbnailImageView loadInBackground:^(UIImage *image, NSError *error) {
   if (!error) {
   if (image) {
   UIImage *maskImage;
   if (image.size.height > image.size.width) {
   maskImage = [UIImage imageNamed:@"thumbnail_mask_portrait"];
   } else {
   maskImage = [UIImage imageNamed:@"thumbnail_mask_landscape"];
   }
   cell.thumbnailImageView.image = [VYBUtility maskImage:image withMask:maskImage];
   } else {
   cell.thumbnailImageView.image = [UIImage imageNamed:@"Oval_mask"];
   }
   }
   }];
   */
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  
  NSInteger section = indexPath.section;
  
  // Active Location
  if (section == 0) {
    Zone *zone = self.activeLocations[indexPath.row];

    // GA stuff
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
      NSString *dimensionValue = @"active unlocked";
      [tracker set:[GAIFields customDimensionForIndex:1] value:dimensionValue];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    playerVC.delegate = self;
    [playerVC playFreshVybesFromZone:zone.zoneID];
  }
  else {
    // GA stuff
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
      NSString *dimensionValue = @"my unlocked";
      [tracker set:[GAIFields customDimensionForIndex:1] value:dimensionValue];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    VYBPlayerViewController *playerController = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
    playerController.delegate = self;
    PFObject *selectedVybe = [self objectAtIndexPath:indexPath];
    [playerController playZoneVybesFromVybe:selectedVybe];
  }
}
  
/*
- (void)didTapOnCell:(VYBVybeTableViewCell *)cell {

    // UNLOCKED zone selected
    else {
        if (cell.tag == _selectedSection) {
            _selectedSection = -1;
            
            Zone *zoneToCollapse = self.sections[cell.tag];
            NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];
            for (int i = 0; i < zoneToCollapse.myVybes.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:cell.tag];
                [pathsToRemove addObject:indexPath];
            }
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:pathsToRemove withRowAnimation:UITableViewRowAnimationMiddle];
            [self.tableView endUpdates];
        }
        else {
            NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];

            if (_selectedSection >= 0) {
                Zone *zoneToCollapse = self.sections[_selectedSection];
                for (int i = 0; i < zoneToCollapse.myVybes.count; i++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:_selectedSection];
                    [pathsToRemove addObject:indexPath];
                }
            }
            
            _selectedSection = cell.tag;

            Zone *zoneToExpand = self.sections[cell.tag];
            NSMutableArray *pathsToAdd = [[NSMutableArray alloc] init];
            for (int i = 0; i < zoneToExpand.myVybes.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:cell.tag];
                [pathsToAdd addObject:indexPath];
            }
            
            
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:pathsToAdd withRowAnimation:UITableViewRowAnimationMiddle];
            if (pathsToRemove.count > 0)
                [self.tableView deleteRowsAtIndexPaths:pathsToRemove withRowAnimation:UITableViewRowAnimationMiddle];
            [self.tableView endUpdates];
        }
    }
}

*/
#pragma mark UITableViewDataSource


#pragma mark Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ShowActiveMap"])
    {
        VYBMapViewController *mapVC = segue.destinationViewController;
        [mapVC displayAllActiveVybes];
    }
}

#pragma mark - PlayerViewControllerDelegate

- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

    if (ready) {
        [self presentViewController:playerVC animated:YES completion:nil];
    }
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
