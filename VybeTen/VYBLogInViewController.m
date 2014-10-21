//
//  VYBLogInViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLogInViewController.h"
#import "VYBSignUpViewController.h"
#import "VYBUtility.h"
#import "NSString+Email.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBLogInViewController ()

@property (nonatomic, weak) IBOutlet UIButton *logInButton;
@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpacing;

- (IBAction)logInButtonPressed:(id)sender;

@end

@implementation VYBLogInViewController

#pragma mark - Lifecycle

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
    
    self.navigationController.navigationBarHidden = NO;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    [self.view endEditing:YES];
    
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.passwordTextField.secureTextEntry = YES;
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_title.png"]];
    [self.navigationItem setTitleView:titleImageView];
    
    UIFont *theFont = [UIFont fontWithName:@"Helvetica Neue" size:15.0];
    NSDictionary *stringAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:72.0/255.0 green:72.0/255.0 blue:72.0/255.0 alpha:1.0],
                                        NSFontAttributeName : theFont};
    self.usernameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username" attributes:stringAttributes];
    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:stringAttributes];
    
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.usernameTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];
    [self.passwordTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];
    
    [self.usernameTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)logInButtonPressed:(id)sender {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Check if the user entered an email instead of a username
    if ([username isValidEmail]) {
        // Fetch the username corresponding to that email
        PFQuery *query = [PFUser query];
        [query whereKey:@"email" equalTo:username.lowercaseString];
        NSArray *foundUsers = [query findObjects];
        
        if([foundUsers count]  == 1) {
            for (PFUser *foundUser in foundUsers) {
                username = [foundUser username];
            }
        }
    }
    
    //log in
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if (!error) {
            if ([PFUser currentUser]) {
                if (self.delegate)
                    [self.delegate logInViewController:self didLogInUser:user];
            }
        } else {
            if (error.code == 101) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                                    message:@"Incorrect email or password"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                                    message:error.userInfo[@"error"]
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
    }];
    
}

#pragma mark - VYBSignUpViewControllerDelegate

- (void)signUpCompleted {
    [self dismissViewControllerAnimated:NO completion:^{
        [self.navigationController popViewControllerAnimated:NO];
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        return NO;
    }
    
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self logInButtonPressed:nil];
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
    [self.usernameTextField becomeFirstResponder];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
