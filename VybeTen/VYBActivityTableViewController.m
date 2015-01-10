//
//  VYBActivityTableViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
#import "VybeTen-Swift.h"

#import "VYBActivityTableViewController.h"
#import "VYBVybeTableViewCell.h"

#import "VYBAppDelegate.h"
#import "VYBCaptureViewController.h"

#import "VYBUtility.h"
#import "VYBCache.h"

#import "VYBPlayerViewController.h"

@interface VYBActivityTableViewController () <UIAlertViewDelegate, VYBPlayerViewControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) UIButton *uploadStatusButton;
@property (strong, nonatomic) UIView *bottomBarMenu;

@property (nonatomic) NSArray *activeLocations;
@property (nonatomic) NSArray *myLocations;

//@property (nonatomic) SimpleInteractionManager *swipeInteractionManager;

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation VYBActivityTableViewController {
  NSInteger _selectedMyLocationIndex;
}
@synthesize uploadStatusButton, bottomBarMenu;

#pragma mark - Lifecycle

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBSwipeContainerControllerWillMoveToActivityScreenNotification object:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.activeLocations = [NSArray array];
    self.myLocations = [NSArray array];
    
    _selectedMyLocationIndex = -1;
    
    self.paginationEnabled = NO;
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToTop:) name:UIApplicationWillEnterForegroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToTop:) name:VYBSwipeContainerControllerWillMoveToActivityScreenNotification object:nil];
  
  self.usernameLabel.text = [PFUser currentUser].username;
  
  // Remove empty cells.
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  
  _selectedMyLocationIndex = -1;
  
  uploadStatusButton = (UIButton *)[[[NSBundle mainBundle] loadNibNamed:@"UploadProgressBottomBar" owner:self options:nil] firstObject];
  [uploadStatusButton setFrame:CGRectMake(0, 0, self.view.bounds.size.width, uploadStatusButton.bounds.size.height)];
  [self.view addSubview:uploadStatusButton];
  uploadStatusButton.hidden = YES;
  
  bottomBarMenu = (UIView *)[[[NSBundle mainBundle] loadNibNamed:@"BottomBarMenu" owner:self options:nil] lastObject];
  [bottomBarMenu setFrame:CGRectMake(0, 0, self.view.bounds.size.width, bottomBarMenu.bounds.size.height)];
  [self.view addSubview:bottomBarMenu];
  
  UIButton *playAllButton = (UIButton *)[bottomBarMenu viewWithTag:3];
  [playAllButton addTarget:self action:@selector(playAllButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  UIButton *bumpsButton = (UIButton *)[bottomBarMenu viewWithTag:7];
  [bumpsButton addTarget:self action:@selector(bumpsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Update Activity count
  [[VYBCache sharedCache] refreshBumpsForMeInBackground:^(BOOL success) {
    if (success) {
      [self updateBumpForMeCount];
    }
  }];
  
  [self updatePlayAllButton];
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

#ifdef DEBUG
  // We want to exclude debugging from analytics.
#else
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    [tracker set:kGAIScreenName
           value:@"Activity Screen"];
    
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
  }
#endif
  
  [self getPermissionIfNeeded];
  [[ConfigManager sharedInstance] fetchIfNeeded];
}

#pragma mark - UIView

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - IBActions

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender {
  SwipeContainerController *swipeContainer = (SwipeContainerController *)self.parentViewController.parentViewController;
  [swipeContainer moveToCaptureScreenWithAnimation:YES];
}

- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles:@"Unblock Users", nil];
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


#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
  PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
  [query whereKey:kVYBVybeUserKey equalTo:[PFUser currentUser]];
  [query includeKey:kVYBVybeUserKey];
  [query orderByDescending:kVYBVybeTimestampKey];
//  [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
  [query setLimit:1000];
  
  return query;
}

- (void)objectsDidLoad:(NSError *)error {
  [super objectsDidLoad:error];
  
  // Update Activity count
  [[VYBCache sharedCache] refreshBumpsForMeInBackground:^(BOOL success) {
    if (success) {
      [self updateBumpForMeCount];
    }
  }];
  
  [[ZoneStore sharedInstance] didFetchUnlockedVybes:self.objects completionHandler:^(BOOL success) {
    if (success) {
      self.activeLocations = [[ZoneStore sharedInstance] activeAndFeaturedZones];
      self.myLocations = [[ZoneStore sharedInstance] unlockedZones];
      
      NSString *locationCntText = (self.myLocations.count > 1) ? [NSString stringWithFormat:@"%d Locations", (int)self.myLocations.count] : [NSString stringWithFormat:@"%d Location", (int)self.myLocations.count];
      NSString *vybeCntText = (self.objects.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)self.objects.count] : [NSString stringWithFormat:@"%d Vybe", (int)self.objects.count];
      
      self.countLabel.text = [NSString stringWithFormat:@"%@ - %@", locationCntText, vybeCntText];
    }
    
    [self addSavedVybesToTable];
    [self updatePlayAllButton];
    [self.tableView reloadData];
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
    Zone *zone = self.activeLocations[indexPath.row];
    NSArray *freshContents = [[ZoneStore sharedInstance] freshVybesFromZone:zone.zoneID];
    VYBVybeTableViewCell *cell;
    PFObject *lastVybe;
    
    if (zone.isFeatured) { // FEATURED zone
      cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"FeaturedLocationCell"];
      
      cell.locationLabel.text = zone.name;
      
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@", [VYBUtility reverseTime:zone.fromDate]];
      PFFile *thumbnailFile = [zone featuredThumbnailFile];
      if (thumbnailFile) {
        cell.thumbnailImageView.file = thumbnailFile;
        [cell.thumbnailImageView loadInBackground:^(UIImage *image, NSError *error) {
          if (!error) {
            if (image) {
              UIImage *maskImage;
              if (image.size.height > image.size.width) {
                if ([zone.name isEqualToString:@"New City Gas"]) {
                  maskImage = [UIImage imageNamed:@"thumbnail_mask_portrait_old"];
                } else {
                  maskImage = [UIImage imageNamed:@"thumbnail_mask_portrait"];
                }
              } else {
                if ([zone.name isEqualToString:@"New City Gas"]) {
                  maskImage = [UIImage imageNamed:@"thumbnail_mask_landscape_old"];
                } else {
                  maskImage = [UIImage imageNamed:@"thumbnail_mask_landscape"];
                }
              }
              cell.thumbnailImageView.image = [VYBUtility maskImage:image withMask:maskImage];
            } else {
              cell.thumbnailImageView.image = [UIImage imageNamed:@"Placeholder"];
            }
          }
        }];
      }
      
      return cell;
      
    } else if (freshContents && freshContents.count) {        // FRESH zone
      cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"UnwatchedActiveLocationCell"];
      
      lastVybe = zone.freshContents.lastObject;
      NSDate *timestampDate = lastVybe[kVYBVybeTimestampKey];
      
      NSString *vybeCntText = (freshContents.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)freshContents.count] : [NSString stringWithFormat:@"%d Vybe", (int)freshContents.count];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
    }
    else {
      cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ActiveLocationCell"];

      lastVybe = zone.mostRecentVybe;
      NSDate *timestampDate = zone.mostRecentActiveVybeTimestamp;
      
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@", [VYBUtility reverseTime:timestampDate]];
    }
    
    cell.locationLabel.text = zone.name;
    
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
          cell.thumbnailImageView.image = [UIImage imageNamed:@"Placeholder"];
        }
      }
    }];
    
    return cell;
  }
  // My Locations
  else {
    PFObject *aVybe = [self vybeCellForIndexPath:indexPath];
    
    // Vybe cells
    if (aVybe) {
      VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"MyVybeCell"];
      NSDate *timestampDate = aVybe[kVYBVybeTimestampKey];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@  (%@)", [VYBUtility localizedDateStringFrom:timestampDate], [VYBUtility reverseTime:timestampDate]];
      
      NSNumber *count = [[VYBCache sharedCache] likeCountForVybe:aVybe];
      if (count && [count intValue] > 0) {
        cell.smallBumpImageView.hidden = NO;
        cell.bumpCountLabel.text = [NSString stringWithFormat:@"%@", count];
      }
      else {
        cell.bumpCountLabel.text = @"";
        cell.smallBumpImageView.hidden = YES;
      }
      
      NSString *localID = aVybe[@"uniqueId"];
      if (localID && localID.length) {
        cell.thumbnailImageView.image = [UIImage imageNamed:@"Gray_Refresh"];
      }
      else {
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
              cell.thumbnailImageView.image = [UIImage imageNamed:@"Placeholder"];
            }
          }
        }];
      }
      
      return cell;
    }
    
    // My Location cell
    else {
      VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"MyLocationCell"];
      
      NSInteger newIndex = [self convertToIndexInMyLocations:indexPath];
      
      Zone *zone = self.myLocations[newIndex];
      if (zone.savedVybes && zone.savedVybes.count) {
        cell.greenLightSavedVybe.hidden = NO;
      }
      else {
        cell.greenLightSavedVybe.hidden = YES;
      }
      
      cell.locationLabel.text = zone.name;
      
      PFObject *lastVybe = zone.myVybes.firstObject;
      NSDate *timestampDate = lastVybe[kVYBVybeTimestampKey];
      
      NSString *vybeCntText = (zone.myVybes.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)zone.myVybes.count] : [NSString stringWithFormat:@"%d Vybe", (int)zone.myVybes.count];
      cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - Last Vybe taken %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
      
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
#ifdef DEBUG
#else
    // GA stuff
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
      NSString *dimensionValue = @"active unlocked";
      [tracker set:[GAIFields customDimensionForIndex:1] value:dimensionValue];
    }
#endif
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    playerVC.delegate = self;
    if (zone.isFeatured) {
      [playerVC playFeaturedZone:zone];
    } else {
      [playerVC playFreshVybesFromZone:zone.zoneID];
    }
  }
  // My Locations
  else {
    PFObject *aVybe = [self vybeCellForIndexPath:indexPath];
    // My vybe cell selected
    if (aVybe) {
      NSString *localID = aVybe[@"uniqueId"];
      if (localID && localID.length) {
        if ( [[MyVybeStore sharedInstance] isUploadingSavedVybes] ) {
          [VYBUtility showToastWithImage:nil title:@"Upload in progress already :)"];
        }
        else {
          [[MyVybeStore sharedInstance] startUploadingSavedVybes];
        }
      }
      else {
#ifdef DEBUG
#else
        // GA stuff
        id tracker = [[GAI sharedInstance] defaultTracker];
        if (tracker) {
          NSString *dimensionValue = @"my unlocked";
          [tracker set:[GAIFields customDimensionForIndex:1] value:dimensionValue];
        }
#endif
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        VYBPlayerViewController *playerController = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        playerController.delegate = self;
        [playerController playZoneVybesFromVybe:aVybe];
      }
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
        if (pathsToRemove.count > 0) {
          [self.tableView deleteRowsAtIndexPaths:pathsToRemove withRowAnimation:UITableViewRowAnimationMiddle];
        }
        [self.tableView endUpdates];
      }
      
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  PFObject *obj = [self vybeCellForIndexPath:indexPath];
  if (obj) {
    return YES;
  }
  return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    PFObject *obj = [self vybeCellForIndexPath:indexPath];
    
    // Saved vybes only need to be deleted locally
    NSString *localID = obj[@"uniqueId"];
    if (localID && localID.length) {
      [[MyVybeStore sharedInstance] deleteSavedVybe:obj];
      [[ZoneStore sharedInstance] deleteSavedVybeLocally:obj];
      [self didDeleteMyVybe];
    } else {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      [[ZoneStore sharedInstance] deleteMyVybeInBackground:obj completionHandler:^(BOOL success) {
        if (success) {
          [self didDeleteMyVybe];
        }
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
      }];
    }
  }
}

#pragma mark - Helpers

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

- (void)didDeleteMyVybe {
  NSArray *newArr = [[ZoneStore sharedInstance] unlockedZones];
  // My Location zone cell will be entirely gone so we want to reset selectedIndex to default
  if (newArr.count < self.myLocations.count) {
    _selectedMyLocationIndex = -1;
  }
  self.myLocations = newArr;
  
  [self.tableView reloadData];
}

- (IBAction)uploadStatusButtonPressed:(id)sender {
  [[MyVybeStore sharedInstance] startUploadingSavedVybes];
}

- (void)uploadFailDetected {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *title = @"SAVED";
    [uploadStatusButton setTitle:title forState:UIControlStateNormal];
    [self addSavedVybesToTable];
    [self.tableView reloadData];
  });
}

- (void)addSavedVybesToTable {
  [[ZoneStore sharedInstance] addSavedVybesToUnlockedZones];
  self.myLocations = [[ZoneStore sharedInstance] unlockedZones];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // Adjust y-positions of two hovering buttons
  CGRect frame = uploadStatusButton.frame;
  frame.origin.y = scrollView.contentOffset.y + self.tableView.frame.size.height - uploadStatusButton.frame.size.height;
  uploadStatusButton.frame = frame;
  bottomBarMenu.frame = frame;
  
  if (!uploadStatusButton.hidden) {
    [self.view bringSubviewToFront:uploadStatusButton];
  }
  if (!bottomBarMenu.hidden) {
    [self.view bringSubviewToFront:bottomBarMenu];
  }
  // Hide Notification Bar when scroll up and show when down
  CGPoint velocity = [[scrollView panGestureRecognizer] velocityInView:self.view];
  if (velocity.y < 0) {
    if (!bottomBarMenu.hidden) {
      bottomBarMenu.hidden = YES;
      [bottomBarMenu setNeedsDisplay];
    }
  } else if (velocity.y > 0) {
    if (bottomBarMenu.hidden) {
      bottomBarMenu.hidden = NO;
      [bottomBarMenu setNeedsDisplay];
    }
  }
}

- (void)scrollToTop:(id)sender {
  // First collapse all the cells
  _selectedMyLocationIndex = -1;
  
  [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

#pragma mark - PlayerViewControllerDelegate

- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready {
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
  
  if (ready) {
    [self presentViewController:playerVC animated:YES completion:nil];
  }
}

#pragma mark - Bottom Menu Bar

- (void)playAllButtonPressed:(id)sender {
  VYBPlayerViewController *playerViewController = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
  playerViewController.delegate = self;
  
  UIButton *playAllButton = (UIButton *)[bottomBarMenu viewWithTag:3];
  if (playAllButton.selected) {
    [playerViewController playAllFresh];
  } else {
    [playerViewController playAllActiveVybes];
  }
}

- (void)bumpsButtonPressed:(id)sender {
  NotificationTableViewController *notificationTable = (NotificationTableViewController *)[[UIStoryboard storyboardWithName:@"Notification" bundle:nil] instantiateInitialViewController];
  [self.navigationController pushViewController:notificationTable animated:YES];
}

- (void)updateBumpForMeCount {
  NSInteger count = [[VYBCache sharedCache] newBumpActivityCountForCurrentUser];
  UIButton *bumpsButton = (UIButton *)[bottomBarMenu viewWithTag:7];
  
  if (count > 0) {
    [bumpsButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
  } else {
    [bumpsButton setTitle:@"BUMPS" forState:UIControlStateNormal];
  }
}

- (void)updatePlayAllButton {
  NSInteger freshCount = [[[ZoneStore sharedInstance] allFreshVybes] count];
  UIButton *playAllButton = (UIButton *)[bottomBarMenu viewWithTag:3];
  playAllButton.selected = (freshCount > 0);
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0) {
      [(VYBAppDelegate *)[UIApplication sharedApplication].delegate logOut];
  } else if (buttonIndex == 1) {
    BlockedUsersTableViewController *blockedUsersTable = [[UIStoryboard storyboardWithName:@"UnblockUser"bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:blockedUsersTable animated:NO];
  } else {
    
  }
}

- (BOOL)prefersStatusBarHidden {
  return NO;
}

@end
