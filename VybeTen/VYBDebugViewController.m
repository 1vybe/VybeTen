//
//  VYBDebugViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBDebugViewController.h"

@interface VYBDebugViewController ()

@property (nonatomic) NSInteger debugMode;
@property (nonatomic, strong) IBOutlet UIButton *button1;
@property (nonatomic, strong) IBOutlet UIButton *button2;
@property (nonatomic, strong) IBOutlet UIButton *button3;

- (IBAction)button1Pressed:(id)sender;
- (IBAction)button2Pressed:(id)sender;
- (IBAction)button3Pressed:(id)sender;

@end

@implementation VYBDebugViewController

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
    // Add tap gesture
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwice)];
    tapTwice.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapTwice];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.delegate) {
        NSInteger debugMode = [self.delegate debugMode];
        if (debugMode == 1) {
            self.button1.selected = YES;
            self.button2.selected = NO;
            self.button3.selected = NO;
        }
        if (debugMode == 2) {
            self.button1.selected = NO;
            self.button2.selected = YES;
            self.button3.selected = NO;
        }
        if (debugMode == 3) {
            self.button3.selected = YES;
            self.button1.selected = NO;
            self.button2.selected = NO;
            self.button3.selected = YES;
        }
    }
}

- (void)tapTwice {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)button1Pressed:(id)sender {
    if (self.delegate) {
        [self.delegate setDebugMode:1];
    }
    self.debugMode = 1;
    self.button1.selected = YES;
    self.button2.selected = NO;
    self.button3.selected = NO;
}

- (IBAction)button2Pressed:(id)sender {
    if (self.delegate) {
        [self.delegate setDebugMode:2];
    }
    self.debugMode = 2;
    self.button1.selected = NO;
    self.button2.selected = YES;
    self.button3.selected = NO;
}

- (IBAction)button3Pressed:(id)sender {
    if (self.delegate) {
        [self.delegate setDebugMode:3];
    }
    self.debugMode = 3;
    self.button1.selected = NO;
    self.button2.selected = NO;
    self.button3.selected = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
