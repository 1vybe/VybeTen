//
//  VYBLogInViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLogInViewController.h"
#import "VYBSignUpViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBLogInViewController ()

@property (nonatomic, strong) IBOutlet UIButton *logInButton;
@property (nonatomic, strong) IBOutlet UIButton *signUpButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;

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
    
    [self.view endEditing:YES];
    
    self.passwordTextField.delegate = self;
    
    self.passwordTextField.secureTextEntry = YES;
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)logInButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //log in
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
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
    VYBSignUpViewController *signUpVC = [[VYBSignUpViewController alloc] init];
    signUpVC.delegate = self;
    [self presentViewController:signUpVC animated:NO completion:nil];
}

- (void)signUpCompleted {
    [self dismissViewControllerAnimated:NO completion:^{
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [textField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
