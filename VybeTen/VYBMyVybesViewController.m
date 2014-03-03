//
//  VYBMyVybesViewController.m
//  VybeTen
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMyVybesViewController.h"
#import "VYBVybeStore.h"
#import "VYBVybe.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"

@interface VYBMyVybesViewController ()

@end

@implementation VYBMyVybesViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
        // Rotate the tableView for horizontal scrolling
        CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
        self.tableView.transform = rotateTable;
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.tableView setRowHeight:200.0f];
        self.tableView.showsVerticalScrollIndicator = NO;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
  }

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[VYBVybeStore sharedStore] myVybes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
        cell.backgroundColor = [UIColor clearColor];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    }
    VYBVybe *vybe = [[[VYBVybeStore sharedStore] myVybes] objectAtIndex:[indexPath row]];
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:[vybe getThumbnailPath]];
    if (!thumbImg) {
        thumbImg = [UIImage imageWithContentsOfFile:[vybe getThumbnailPath]];
        [[VYBImageStore sharedStore] setImage:thumbImg forKey:[vybe getThumbnailPath]];
    }
    // Crop Image to 180 x 180
    UIImageView *thumbImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];
    [thumbImgView setImage:thumbImg];
    // Move the thumbnail image so its center aligns with the center of a cell's cententView
    CGRect newFrame = thumbImgView.frame;
    newFrame.origin.x = cell.contentView.center.x - 90.0f;
    newFrame.origin.y = cell.contentView.center.y - 90.0f;
    [thumbImgView setFrame:newFrame];
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    thumbImgView.transform = rotate;
    // Crop the image to circle
    CALayer *layer = cell.backgroundView.layer;
    [layer setCornerRadius:cell.backgroundView.frame.size.width/2];
    [layer setMasksToBounds:YES];
    
    [cell setBackgroundView:thumbImgView];
    
    NSLog(@"bgView has frame:%@",NSStringFromCGRect(cell.backgroundView.frame));
    NSLog(@"bgView has bounds:%@",NSStringFromCGRect(cell.backgroundView.bounds));

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundView.bounds = CGRectMake(0, 0, 180, 180);
    NSLog(@"[display]bgView has frame:%@",NSStringFromCGRect(cell.backgroundView.frame));
    NSLog(@"[display]bgView has bounds:%@",NSStringFromCGRect(cell.backgroundView.bounds));
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"SELECTED");
    [self.navigationController popToRootViewControllerAnimated:NO];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
