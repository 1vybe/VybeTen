//
//  VYBLogInViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLogInViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBLogInViewController ()

@property (nonatomic, strong) IBOutlet UIButton *logInButton;
@property (nonatomic, strong) IBOutlet UIButton *signUpButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;

- (IBAction)logInButtonPressed:(id)sender;
- (IBAction)signUpButtonPressed:(id)sender;

@end

@implementation VYBLogInViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)logInButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //log in
    [PFUser logInWithUsernameInBackground:username password:username block:^(PFUser *user, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if (!error) {
            if ([PFUser currentUser]) {
                [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            }
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }];

}

- (IBAction)signUpButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;

    // sign up
    PFUser *newUser = [PFUser user];
    newUser.username = username;
    newUser.password = username;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if (!error) {
            if ([PFUser currentUser]) {
                [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            }
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }];

}

#pragma mark - UIDeviceOrientation




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
