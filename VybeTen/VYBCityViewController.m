//
//  VYBCityViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCityViewController.h"
#import "VYBPlayerViewController.h"

@interface VYBCityViewController ()

@end

@implementation VYBCityViewController

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"All" style:UIBarButtonItemStylePlain target:self action:@selector(allButtonItemPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blueColor];

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
    PFQuery *query = [PFQuery queryWithClassName:kVYBCityClassKey];

    return query;
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CityTableCellIdentifier = @"CityTableCellIdentifer";
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CityTableCellIdentifier];
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CityTableCellIdentifier];
    }
    cell.textLabel.text = object[kVYBCityNameKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aCity = self.objects[indexPath.row];
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:YES];
    [playerVC setCurrCity:aCity];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)allButtonItemPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:YES];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
