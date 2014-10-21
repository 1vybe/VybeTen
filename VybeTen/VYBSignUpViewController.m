//
//  VYBSignUpViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBSignUpViewController.h"
#import "NSString+Username.h"
#import "NSString+Email.m"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBSignUpViewController () 

@property (nonatomic, weak) IBOutlet UIButton *signUpButton;
@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpacing;

- (IBAction)signUpButtonPressed:(id)sender;

@end

@implementation VYBSignUpViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

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
    
    //[self.view endEditing:YES];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.passwordTextField.secureTextEntry = YES;
    // Do any additional setup after loading the view from its nib.
    
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.emailTextField.delegate = self;
    
    self.navigationController.navigationBarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"signup_title.png"]];
    [self.navigationItem setTitleView:titleImageView];
    
    UIFont *theFont = [UIFont fontWithName:@"Helvetica Neue" size:15.0];
    NSDictionary *stringAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:72.0/255.0 green:72.0/255.0 blue:72.0/255.0 alpha:1.0],
                                        NSFontAttributeName : theFont};
    self.usernameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username" attributes:stringAttributes];
    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:stringAttributes];
    self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email" attributes:stringAttributes];
    
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.emailTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.usernameTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];
    [self.passwordTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];
    [self.emailTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];

    [self.usernameTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}


- (IBAction)signUpButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *email = self.emailTextField.text;
    
    if (username.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Username Required"
                                                            message:@"Please enter your username."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 200;
        [alertView show];
    } else if (![username isValidUsername]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Valid Username Required"
                                                            message:@"Username must only contain alphanumeric characters and underscores. Please choose different username."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 109;
        [alertView show];
    } else if (email.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Required"
                                                            message:@"Please enter your email."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 204;
        [alertView show];
    } else if (![email isValidEmail]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Valid Email Required"
                                                            message:@"Please enter a valid email."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 125;
        [alertView show];
    } else if (password.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Required"
                                                            message:@"Please enter your password."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 201;
        [alertView show];
    } else if (password.length < 6) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Too Short"
                                                            message:@"Passwords must be at least 6 characters. Please choose a longer password."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = 110;
        [alertView show];
    } else {
        // sign up
        PFUser *newUser = [PFUser user];
        newUser.username = username;
        newUser.password = password;
        newUser.email = email.lowercaseString;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                if ([PFUser currentUser]) {
                    if (self.delegate)
                        [self.delegate didCompleteSignUp];
                }
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = error.code;
                [alertView show];
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        return NO;
    }
    
    if (textField == self.usernameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self signUpButtonPressed:nil];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField != self.passwordTextField) {
        textField.returnKeyType = UIReturnKeyNext;
    } else {
        textField.returnKeyType = UIReturnKeyGo;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    CGSize keyboardSize = [[dictionary objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSNumber *duration = [dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = [duration doubleValue];
    [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.bottomSpacing.constant = keyboardSize.height;
    } completion:nil];
    
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    
    NSNumber *duration = [dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = [duration doubleValue];
    [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.bottomSpacing.constant = 0;
    } completion:nil];
    
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    /* Tags
     109 username is invalid
     110 password is invalid
     125 email is invalid
     200 username is missing or empty
     201 password is missing or empty
     202 username has already been taken
     203 email has already been taken
     204 email is missing or empty
     */
    if (alertView.tag == 200 || alertView.tag == 202) {
        [self.usernameTextField becomeFirstResponder];
    } else if (alertView.tag == 125 || alertView.tag == 203 || alertView.tag == 204) {
        [self.emailTextField becomeFirstResponder];
    } else if (alertView.tag == 201) {
        [self.passwordTextField becomeFirstResponder];
    }
}

# pragma mark -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
