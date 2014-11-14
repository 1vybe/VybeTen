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

@interface VYBActivityTableViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (retain, nonatomic) NSArray *sections;
@property (retain, nonatomic) NSMutableDictionary *sectionToZoneNameMap;

- (IBAction)captureButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)settingsButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation VYBActivityTableViewController {
    NSInteger _selectedSection;
}

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.parseClassName = kVYBVybeClassKey;
        self.paginationEnabled = NO;
        self.pullToRefreshEnabled = YES;
        self.objectsPerPage = 500;
        self.sections = [NSArray array];
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
    
    _selectedSection = -1;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadObjects];
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
            self.sections = [[ZoneStore sharedInstance] allUnlockedZones];
            
            NSString *locationCntText = (self.sections.count > 1) ? [NSString stringWithFormat:@"%d Locations", (int)self.sections.count] : [NSString stringWithFormat:@"%d Location", (int)self.sections.count];
            NSString *vybeCntText = (self.objects.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)self.objects.count] : [NSString stringWithFormat:@"%d Vybe", (int)self.objects.count];

            self.countLabel.text = [NSString stringWithFormat:@"%@ - %@", locationCntText, vybeCntText];
            
            [self.tableView reloadData];
        }
    }];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    Zone *zone = self.sections[indexPath.section];
    PFObject *vybe = [zone.myVybes objectAtIndex:indexPath.row];
//    NSArray *rowIndecesInSection = [];
    
    return vybe;
}


#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    VYBVybeTableViewCell *cell = (VYBVybeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    
    Zone *zone = self.sections[section];
    cell.locationLabel.text = zone.name;
    
    UIButton *button = (UIButton *)[cell viewWithTag:666];
    button.tag = section;
    
    PFObject *lastVybe;
    
    if (zone.numOfActiveVybes > 0) {
        lastVybe = zone.mostRecentVybe;
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
    }
    else {
        lastVybe = zone.myVybes.firstObject;
        NSDate *timestampDate = lastVybe[kVYBVybeTimestampKey];
        
        NSString *vybeCntText = (zone.myVybes.count > 1) ? [NSString stringWithFormat:@"%d Vybes", (int)zone.myVybes.count] : [NSString stringWithFormat:@"%d Vybe", (int)zone.myVybes.count];
        cell.timestampLabel.text = [NSString stringWithFormat:@"%@ - Last Vybe taken %@", vybeCntText, [VYBUtility reverseTime:timestampDate]];
        cell.thumbnailImageView.hidden = YES;
    }
    
    return cell.contentView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    VYBPlayerViewController *playerController = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];

    [self presentViewController:playerController animated:YES completion:^{
        PFObject *selectedVybe = [self objectAtIndexPath:indexPath];
        [playerController playZoneVybesFromVybe:selectedVybe];
    }];
}

- (IBAction)sectionClicked:(UIButton *)sectionButton {
    Zone *zone = self.sections[sectionButton.tag];
    // ACTIVE zone selected
    if (zone.numOfActiveVybes > 0) {
        
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
        [self presentViewController:playerVC animated:YES completion:^{
            [playerVC playFreshVybesFromZone:zone.zoneID];
        }];
    }
    // UNLOCKED zone selected
    else {
        if (sectionButton.tag == _selectedSection) {
            _selectedSection = -1;
            
            Zone *zoneToCollapse = self.sections[sectionButton.tag];
            NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];
            for (int i = 0; i < zoneToCollapse.myVybes.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionButton.tag];
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
            
            _selectedSection = sectionButton.tag;

            Zone *zoneToExpand = self.sections[sectionButton.tag];
            NSMutableArray *pathsToAdd = [[NSMutableArray alloc] init];
            for (int i = 0; i < zoneToExpand.myVybes.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionButton.tag];
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


#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.sections) {
        return 0;
    }
    
    if (section != _selectedSection) {
        return 0;
    }
    
    if (self.sections && self.sections.count > 0) {
        Zone *zone = self.sections[section];
        return zone.myVybes.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
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
    
    return cell;
}

#pragma mark Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ShowActiveMap"])
    {
        VYBMapViewController *mapVC = segue.destinationViewController;
        [mapVC displayAllActiveVybes];
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
