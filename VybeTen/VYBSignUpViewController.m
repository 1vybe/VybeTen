//
//  VYBSignUpViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBSignUpViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBSignUpViewController () 

@property (nonatomic, strong) IBOutlet UIButton *logInButton;
@property (nonatomic, strong) IBOutlet UIButton *signUpButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) IBOutlet UITextField *emailTextField;

- (IBAction)logInButtonPressed:(id)sender;
- (IBAction)signUpButtonPressed:(id)sender;

@end

@implementation VYBSignUpViewController

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

    self.passwordTextField.secureTextEntry = YES;
    // Do any additional setup after loading the view from its nib.
    
    self.emailTextField.delegate = self;
}

- (IBAction)logInButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)signUpButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *email = self.emailTextField.text;
    
    if (username && [username length] > 0 && password && [password length] > 0 && email && [email length] > 0) {
        // sign up
        PFUser *newUser = [PFUser user];
        newUser.username = username;
        newUser.password = password;
        newUser.email = email;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                if ([PFUser currentUser]) {
                    if ( self.delegate && [self.delegate respondsToSelector:@selector(signUpCompleted)] ) {
                        [self.delegate performSelector:@selector(signUpCompleted) withObject:nil];
                    }
                }
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        }];

        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Please fill in all required fields" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    
  
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
