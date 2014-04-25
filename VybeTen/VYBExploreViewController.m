//
//  VYBExploreViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBExploreViewController.h"
#import "VYBMenuViewController.h"
#import "VYBMyTribeStore.h"
#import "VYBTribeVybesViewController.h"
#import "VYBImageStore.h"
#import "VYBPlayerViewController.h"

@implementation VYBExploreViewController {
    UIView *topBar;
    UIView *sideBar;
    //UILabel *currentStageLabel;
    UILabel *currentTabLabel;
    
    UIButton *searchButton;
    UIButton *captureButton;
    UIButton *menuButton;
    UIButton *featuredButton;
    UIButton *happeningButton;
    UIButton *trendingButton;
    
    UICollectionView *collection;
    UICollectionViewFlowLayout *flowLayout;
    
    UIImageView *mapView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleBlack];
    [self.view addSubview:backView];
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 50, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    // Adding SEARCH button
    frame = CGRectMake(self.view.bounds.size.height - 100, 0, 50, 50);
    searchButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *searchImg = [UIImage imageNamed:@"button_search.png"];
    [searchButton setImage:searchImg forState:UIControlStateNormal];
    [topBar addSubview:searchButton];
    // Adding Label
    frame = CGRectMake(10, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"FEATURED"];
    [topBar addSubview:currentTabLabel];
    
    // Adding a transparent SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:sideBar];
    
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    [menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:menuButton];
    
    frame = CGRectMake(0, 50, 50, (self.view.bounds.size.width - 100)/3);
    featuredButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *featuredImg = [UIImage imageNamed:@"button_featured.png"];
    // By default, FEATURED is chosen
    [featuredButton setBackgroundColor:[UIColor clearColor]];
    [featuredButton setImage:featuredImg forState:UIControlStateNormal];
    [featuredButton addTarget:self action:@selector(tapOnFeatured:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:featuredButton];
    /*
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(10, (self.view.bounds.size.width - 100)/3, 30, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [featuredButton.layer addSublayer:bottomBorder];
    */
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)/3, 50, (self.view.bounds.size.width - 100)/3);
    happeningButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *happeningImg = [UIImage imageNamed:@"button_happening.png"];
    [happeningButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [happeningButton setImage:happeningImg forState:UIControlStateNormal];
    [happeningButton addTarget:self action:@selector(tapOnHappening:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:happeningButton];
    /*
    CALayer *bottomBorder2 = [CALayer layer];
    bottomBorder2.frame = CGRectMake(10, (self.view.bounds.size.width - 100)/3, 30, 1.0f);
    bottomBorder2.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [happeningButton.layer addSublayer:bottomBorder2];
    */
    
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)*2/3, 50, (self.view.bounds.size.width - 100)/3);
    trendingButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *trendingImg = [UIImage imageNamed:@"button_trending.png"];
    [trendingButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [trendingButton addTarget:self action:@selector(tapOnTrending:) forControlEvents:UIControlEventTouchUpInside];
    [trendingButton setImage:trendingImg forState:UIControlStateNormal];
    [sideBar addSubview:trendingButton];
    
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *captureImg = [UIImage imageNamed:@"button_vybe.png"];
    [captureButton setImage:captureImg forState:UIControlStateNormal];
    [captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:captureButton];
    
    flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(50.0f, 10.0f, 20.0f, 10.0f);
    flowLayout.minimumLineSpacing = 50.0f;
    flowLayout.minimumInteritemSpacing = 20.0f;
    flowLayout.itemSize = CGSizeMake(150.0f, 80.0f);
    
    CGRect collectionFrame = CGRectMake(0, 50, self.view.bounds.size.height - 50, self.view.bounds.size.width - 50);
    collection = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:flowLayout];
    [collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collection registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [collection registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    collection.backgroundColor = [UIColor clearColor];
    collection.dataSource = self;
    collection.delegate = self;
    [self.view addSubview:collection];
    
    mapView = [[UIImageView alloc] initWithFrame:collectionFrame];
    [mapView setClipsToBounds:YES];
    [mapView setContentMode:UIViewContentModeScaleAspectFill];
    UIImage *mapImg = [UIImage imageNamed:@"map_image.png"];
    [mapView setImage:mapImg];
    
    [[VYBMyTribeStore sharedStore] refreshTribesWithCompletion:^(NSError *err) {
        [collection reloadData];
    }];
}

- (void)goToMenu:(id)sender {
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    menuVC.view.backgroundColor = [UIColor clearColor];
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //[menuVC setTransitioningDelegate:transitionController];
    //menuVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentViewController:menuVC animated:YES completion:nil];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)tapOnFeatured:(id)sender {
    if ([mapView superview])
        [mapView removeFromSuperview];
    
    [featuredButton setBackgroundColor:[UIColor clearColor]];
    [happeningButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [trendingButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [currentTabLabel setText:@"FEATURED"];
    [collection reloadData];
}

- (void)tapOnHappening:(id)sender {
    [happeningButton setBackgroundColor:[UIColor clearColor]];
    [featuredButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [trendingButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [currentTabLabel setText:@"HAPPENING"];
    [self.view addSubview:mapView];
}

- (void)tapOnTrending:(id)sender {
    if ([mapView superview])
        [mapView removeFromSuperview];
    
    [trendingButton setBackgroundColor:[UIColor clearColor]];
    [happeningButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [featuredButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [currentTabLabel setText:@"TRENDING"];
    [collection reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[VYBMyTribeStore sharedStore] myTribes] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collection dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    VYBTribe *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    NSString *tribeName = [tribe tribeName];
    VYBVybe *vybe = [[tribe vybes] lastObject];
    [cell setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.5]];
    UIImage *img = [[VYBImageStore sharedStore] imageWithKey:[vybe tribeThumbnailPath]];
    if (!img) {
        img = [UIImage imageWithContentsOfFile:[vybe tribeThumbnailPath]];
        if (img) {
            [[VYBImageStore sharedStore] setImage:img forKey:[vybe tribeThumbnailPath]];
        }
    }
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [cell setBackgroundView:imgView];
    
    NSString *title = [self generateFeatureName:tribeName];
    [self cell:cell setTitle:title tribeName:tribeName indexPath:indexPath];
    return cell;
}

- (NSString *)generateFeatureName:(NSString *)name {
    NSString *featureName = @"";
    if ([name isEqualToString:@"MTLBLOG"]) {
        featureName = @"Promoted";
    } else if ([name isEqualToString:@"PEETAPLANET"]) {
        featureName = @"Beautifully Shot";
    } else if ([name isEqualToString:@"CITY-GAS"]) {
        featureName = @"Nightlife";
    } else if ([name isEqualToString:@"FOODIES-MTL"]) {
        featureName = @"Lifestyle";
    } else if ([name isEqualToString:@"MTL-NEXT"]) {
        featureName = @"Startup Scene";
    } else if ([name isEqualToString:@"RUSSIAN"]) {
        featureName = @"Opening This Week";
    }
    return featureName;
}


- (void)cell:(UICollectionViewCell *)cell setTitle:(NSString *)title tribeName:(NSString *)name indexPath:(NSIndexPath *)indexPath {
    // Get current cell size
    //CGSize itemSize = [self collectionView:collection layout:flowLayout sizeForItemAtIndexPath:indexPath];
    int top = -30;
    int width = 150;
    int height = 80;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top, width, 30)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    titleLabel.tag = 777;
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:16]];
    [titleLabel setText:title];
    [self removeReusedLabel:cell tag:777];
    [cell addSubview:titleLabel];
    
    UILabel *tribeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (height - 30)/2, width, 30)];
    [tribeNameLabel setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    tribeNameLabel.tag = 333;
    [tribeNameLabel setTextColor:[UIColor whiteColor]];
    [tribeNameLabel setText:name];
    [tribeNameLabel setTextAlignment:NSTextAlignmentCenter];
    [tribeNameLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [self removeReusedLabel:cell tag:333];
    [cell addSubview:tribeNameLabel];
}

- (void)removeReusedLabel:(UICollectionViewCell *)cell tag:(int)tag {
    UILabel *foundLabelBackground = (UILabel *)[cell viewWithTag:tag];
    if (foundLabelBackground) [foundLabelBackground removeFromSuperview];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    VYBTribe *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    VYBTribeVybesViewController *vybesVC = [[VYBTribeVybesViewController alloc] init];
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    

    //[playerVC setModalTransitionStyle:UIModalTransitionStyleCoverVertical];

    [self.navigationController presentViewController:playerVC animated:NO completion:^(void) {
        if ([[tribe vybes] count] < 1) {
            [[VYBMyTribeStore sharedStore] syncWithCloudForTribe:[tribe tribeName] withCompletionBlock:^(NSError *err) {
                [playerVC setVybePlaylist:[tribe vybes]];
                [playerVC playFromUnwatched];
            }];
        }
        else {
            [playerVC setVybePlaylist:[tribe vybes]];
            [playerVC playFromUnwatched];
        }
        [vybesVC setCurrTribe:tribe];
        [self.navigationController pushViewController:vybesVC animated:NO];
    }];
}

@end
