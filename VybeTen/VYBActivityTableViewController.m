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

#import "VYBMyVybeStore.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate, VYBPlayerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (nonatomic) NSArray *activeLocations;
@property (nonatomic) NSArray *myLocations;
@property (nonatomic) NSArray *expandedVybeCells;
@property (retain, nonatomic) NSMutableDictionary *sectionToZoneNameMap;

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation VYBActivityTableViewController {
  NSInteger _selectedMyLocationIndex;
  
  PFObject *_vybeInUpload;
}

static void *YCContext = &YCContext;

#pragma mark - Lifecycle

- (void)dealloc {
  [[VYBMyVybeStore sharedStore] removeObserver:self forKeyPath:@"currentUploadPercent" context:YCContext];
}

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
    
    _selectedMyLocationIndex = -1;
    
    _vybeInUpload = nil;
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // current video uploading progress is funnelled using KVO. Observer is MyVybeStore
  [[VYBMyVybeStore sharedStore] addObserver:self forKeyPath:@"currentUploadPercent" options:NSKeyValueObservingOptionNew context:YCContext];
  
  self.usernameLabel.text = [PFUser currentUser].username;

  // Remove empty cells.
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  
  self.tableView.delegate = self;
  
  _selectedMyLocationIndex = -1;
  
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

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 36.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    UIView *activeLocations = [[[NSBundle mainBundle] loadNibNamed:@"ActivitySectionView" owner:nil options:nil] firstObject];
    
    return activeLocations;
  }
    
  else {
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ActivitySectionView" owner:nil options:nil];
    UIView *myLocations = array[1];
    
    return myLocations;
  }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return self.activeLocations.count;
  }
  
  if (section == 1) {
    if (_selectedMyLocationIndex < 0) {
      return self.myLocations.count;
    } else {
      Zone *myLocation = self.myLocations[_selectedMyLocationIndex];
      NSInteger numOfMyVybes = myLocation.myVybes.count;
      
      return self.myLocations.count + numOfMyVybes;
    }
  }
  
  return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 1) {
    PFObject *aVybe = [self vybeCellForIndexPath:indexPath];
    if (aVybe) {
      return 70.0f;
    }
  }
  
  return 85.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger section = indexPath.section;
  
  // Active Location Cell
  if (section == 0) {
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    
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
  // My Locations
  else {
    PFObject *aVybe = [self vybeCellForIndexPath:indexPath];
    
    // Vybe Cell
    if (aVybe) {
      VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"VybeCell"];
      NSDate *timestampDate = aVybe[kVYBVybeTimestampKey];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@  (%@)", [VYBUtility localizedDateStringFrom:timestampDate], [VYBUtility reverseTime:timestampDate]];
      
      cell.thumbnailImageView.file = aVybe[kVYBVybeThumbnailKey];
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
    
    // My Location cell
    else {
      VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
      
      cell.thumbnailImageView.hidden = YES;
      
      NSInteger newIndex = [self convertToIndexInMyLocations:indexPath];
      
      Zone *zone = self.myLocations[newIndex];
      
      cell.locationLabel.text = zone.name;
      
      PFObject *lastVybe = zone.myVybes.firstObject;
      NSDate *timestampDate = lastVybe[kVYBVybeTimestampKey];
      
      NSString *vybeCntText = (zone.myVybes.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)zone.myVybes.count] : [NSString stringWithFormat:@"%d Vybe", (int)zone.myVybes.count];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - Last Vybe taken %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
      cell.thumbnailImageView.hidden = YES;
      
      return cell;
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  //[super tableView:tableView didSelectRowAtIndexPath:indexPath];
  
  NSInteger section = indexPath.section;
  
  // Active Locations
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
  // My Locations
  else {
    PFObject *aVybe = [self vybeCellForIndexPath:indexPath];
    // My vybe cell selected
    if (aVybe) {
      // GA stuff
      id tracker = [[GAI sharedInstance] defaultTracker];
      if (tracker) {
        NSString *dimensionValue = @"my unlocked";
        [tracker set:[GAIFields customDimensionForIndex:1] value:dimensionValue];
      }
      
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      VYBPlayerViewController *playerController = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
      playerController.delegate = self;
      [playerController playZoneVybesFromVybe:aVybe];
    }
    // My Location zone cell selected. Rearrange and animate table cells
    else {
      NSInteger rIndex = [self convertToIndexInMyLocations:indexPath];
      // Collapse when clicked again
      if (rIndex == _selectedMyLocationIndex) {
        _selectedMyLocationIndex = -1;
        
        Zone *zoneToCollapse = self.myLocations[rIndex];
        NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];
        for (int i = 0; i < zoneToCollapse.myVybes.count; i++) {
          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rIndex + 1 + i inSection:1];
          [pathsToRemove addObject:indexPath];
        }
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:pathsToRemove withRowAnimation:UITableViewRowAnimationMiddle];
        [self.tableView endUpdates];
      }
      // Collapse existing expanded cells and expand newly selected My Location cell
      else {
        NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];
        
        if (_selectedMyLocationIndex >= 0) {
          Zone *zoneToCollapse = self.myLocations[_selectedMyLocationIndex];
          for (int i = 0; i < zoneToCollapse.myVybes.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_selectedMyLocationIndex + 1 + i inSection:1];
            [pathsToRemove addObject:indexPath];
          }
        }
        
        _selectedMyLocationIndex = rIndex;
        
        Zone *zoneToExpand = self.myLocations[_selectedMyLocationIndex];
        NSMutableArray *pathsToAdd = [[NSMutableArray alloc] init];
        for (int i = 0; i < zoneToExpand.myVybes.count; i++) {
          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_selectedMyLocationIndex + 1 + i inSection:1];
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
}


- (PFObject *)vybeCellForIndexPath:(NSIndexPath *)indexPath {
  // No My Location cell is expanded
  if (_selectedMyLocationIndex < 0) {
    return nil;
  }
  
  // My Location cells above the selected index
  if (indexPath.row <= _selectedMyLocationIndex) {
    return nil;
  }
  
  Zone *selected = self.myLocations[_selectedMyLocationIndex];
  NSInteger numOfMyVybes = selected.myVybes.count;
  
  // My Location celss below the selected index
  if (indexPath.row > _selectedMyLocationIndex + numOfMyVybes) {
    return nil;
  }
  
  return selected.myVybes[indexPath.row - _selectedMyLocationIndex - 1];;
}

- (NSInteger)convertToIndexInMyLocations:(NSIndexPath *)indexPath {
  NSInteger row = [indexPath row];
  
  if (_selectedMyLocationIndex < 0)
    return row;
  
  if (row <= _selectedMyLocationIndex) {
    return row;
  }
  
  Zone *selected = self.myLocations[_selectedMyLocationIndex];
  
  return row - selected.myVybes.count;
}


#pragma mark Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ShowActiveMap"])
    {
        VYBMapViewController *mapVC = segue.destinationViewController;
        [mapVC displayAllActiveVybes];
    }
}

#pragma mark - Current Upload Progress KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == YCContext) {
    if ([keyPath isEqualToString:@"currentUploadPercent"]) {
      int newPercent = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
      [self updateVybeUploadProgress:newPercent];
      return;
    }
  }
  
  [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateVybeUploadProgress:(int)newPercent {

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
