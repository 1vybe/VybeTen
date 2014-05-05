//
//  VYBCreateTribeViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCreateTribeViewController.h"
#import "VYBMyTribeStore.h"

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
    [topBar addSubview:tribeNameTextField];
}

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)createButtonPressed:(id)sender {
    NSString *tribeName = [tribeNameTextField text];
    BOOL success = [[VYBMyTribeStore sharedStore] addNewTribe:tribeName];
    if (success) {
        NSString *msg = [NSString stringWithFormat:@"Awesome! Now %@ is your tribe", tribeName];
        UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [popUp show];
    } else {
        NSString *msg = @"Sorry :( That tribe name is taken";
        UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [popUp show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
