//
//  VYBCreateTribeViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCreateTribeViewController.h"
#import "VYBMyTribeStore.h"
#import "VYBTribeTimelineViewController.h"
#import "VYBUtility.h"

@implementation VYBCreateTribeViewController {
    UIView *topBar;
    
    UIButton *cancelButton;
    UIButton *createButton;
    UIButton *menuButton;
    UITextField *tribeNameTextField;
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
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleBlack];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [backView addGestureRecognizer:tapGesture];
    [self.view addSubview:backView];
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding CANCEL button
    frame = CGRectMake(0, 0, 50, 50);
    cancelButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *cancelImg = [UIImage imageNamed:@"button_cancel.png"];
    [cancelButton setImage:cancelImg forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:cancelButton];
    // Adding CREATE button
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    createButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *createImg = [UIImage imageNamed:@"button_check"];
    [createButton setImage:createImg forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(createButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:createButton];
    // Adding TRIBE NAME textfield
    frame = CGRectMake(50, 0, 250, 50);
    tribeNameTextField = [[UITextField alloc] initWithFrame:frame];
    [tribeNameTextField setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [tribeNameTextField setTextColor:[UIColor whiteColor]];
    [tribeNameTextField becomeFirstResponder];
    UIColor *placeholderColor = [UIColor colorWithWhite:0.7 alpha:0.5];
    tribeNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter a tribe name"
                                                                               attributes:@{NSForegroundColorAttributeName: placeholderColor,
                                                                                            NSFontAttributeName : [UIFont fontWithName:@"Montreal-Xlight" size:20]}];
    [topBar addSubview:tribeNameTextField];
}

- (void)dismissKeyboard:(id)sender {
    [tribeNameTextField resignFirstResponder];
}

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)createButtonPressed:(id)sender {
    NSString *tribeName = [tribeNameTextField text];
    if ([tribeName length] < 2) {
        NSString *msg = @"Tribe name should be at least 2 characters.";
        UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [popUp show];
        return;
    }
    
    else if ([tribeName length] > 10) {
        NSString *msg = @"Tribe name should be less than 10 characters.";
        UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [popUp show];
        return;
    }
    
    PFObject *newTribe = [PFObject objectWithClassName:kVYBTribeClassKey];
    [newTribe setObject:[PFUser currentUser] forKey:kVYBTribeCreatorKey];
    [newTribe setObject:tribeName forKey:kVYBTribeNameKey];
    [newTribe setObject:kVYBTribeTypePrivate forKey:kVYBTribeTypeKey];
    
    PFRelation *relation = [newTribe relationForKey:kVYBTribeMembersKey];
    [relation addObject:[PFUser currentUser]];
    
    PFACL *tribeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [tribeACL setPublicReadAccess:NO];
    newTribe.ACL = tribeACL;
    
    [newTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            VYBTribeTimelineViewController *tribeTimelineVC = [[VYBTribeTimelineViewController alloc] init];
            [tribeTimelineVC setCurrTribe:newTribe];
            [(UINavigationController *)self.presentingViewController pushViewController:tribeTimelineVC animated:NO];
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            
        } else {
            NSString *msg = [NSString stringWithFormat:@"A tribe cannot be created at this time."];
            UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [popUp show];
            NSLog(@"Error while creating a tribe: %@", error);
        }
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
