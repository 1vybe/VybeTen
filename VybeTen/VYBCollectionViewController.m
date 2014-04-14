//
//  VYBCollectionViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCollectionViewController.h"
#import "VYBImageStore.h"
#import "VYBTribe.h"

@implementation VYBCollectionViewController {
    UICollectionView *collection;
    UICollectionViewFlowLayout *flowLayout;
}
@synthesize tribes;

- (id)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.view.frame = frame;
        tribes = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Collection View[%@]", NSStringFromCGRect(self.view.bounds));
    
    [collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"collectionCell"];
    collection.backgroundColor = [UIColor clearColor];
    
    flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(10.0f, 10.0f, 50.0f, 10.0f);
    flowLayout.minimumLineSpacing = 20.0f;
    flowLayout.minimumInteritemSpacing = 20.0f;
    flowLayout.itemSize = CGSizeMake(100.0f, 50.0f);
    
    
    collection = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flowLayout];
    collection.dataSource = self;
    collection.delegate = self;
    self.view = collection;
    
    // Do any additional setup after loading the view.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [tribes count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collection dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
    VYBTribe *tribe = [tribes objectAtIndex:[indexPath row]];
    VYBVybe *vybe = [[tribe vybes] firstObject];
    
    UIImage *cellImg = [[VYBImageStore sharedStore] imageWithKey:[vybe thumbnailPath]];
    if (!cellImg) {
        cellImg = [UIImage imageWithContentsOfFile:[vybe thumbnailPath]];
        [[VYBImageStore sharedStore] setImage:cellImg forKey:[vybe thumbnailPath]];
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:cellImg];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}



@end
