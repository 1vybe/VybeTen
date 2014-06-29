//
//  VYBTribesCell.m
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribeCell.h"


@implementation VYBTribeCell

@synthesize delegate;
@synthesize tribe;
@synthesize thumbnailImageButton;
@synthesize thumbnailImageView;
@synthesize nameButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.thumbnailImageView = [[PFImageView alloc] initWithFrame:CGRectMake(10.0f, 14.0f, 40.0f, 40.0f)];
        [self.contentView addSubview:self.thumbnailImageView];
        
        self.thumbnailImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.thumbnailImageButton.backgroundColor = [UIColor clearColor];
        self.thumbnailImageButton.frame = CGRectMake( 10.0f, 14.0f, 40.0f, 40.0f);
        [self.thumbnailImageButton addTarget:self action:@selector(didTapVybeButtonAction:)
                         forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.thumbnailImageButton];
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.nameButton.backgroundColor = [UIColor clearColor];
        self.nameButton.titleLabel.font = [UIFont fontWithName:@"Montreal-Xlight" size:16.0f];
        self.nameButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.nameButton setTitleColor:[UIColor colorWithRed:87.0f/255.0f green:72.0f/255.0f blue:49.0f/255.0f alpha:1.0f]
                              forState:UIControlStateNormal];
        [self.nameButton setTitleColor:[UIColor colorWithRed:134.0f/255.0f green:100.0f/255.0f blue:65.0f/255.0f alpha:1.0f]
                              forState:UIControlStateHighlighted];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor]
                                    forState:UIControlStateNormal];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor]
                                    forState:UIControlStateSelected];
        [self.nameButton.titleLabel setShadowOffset:CGSizeMake( 0.0f, 1.0f)];
        [self.nameButton addTarget:self action:@selector(didTapTribeButtonAction:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nameButton];
        
    }
    return self;
}


#pragma mark - VYBTribesCell
- (void)setTribe:(PFObject *)aTribe {
    tribe = aTribe;
    
    // Configure the cell
    PFObject *newestVybe = [self.tribe objectForKey:kVYBTribeNewestVybeKey];
    if (newestVybe) {
        [thumbnailImageView setFile:[newestVybe objectForKey:kVYBVybeThumbnailKey]];
        [thumbnailImageView loadInBackground];
    } else {
        [thumbnailImageView setImage:[UIImage imageNamed:@"button_player_capture.png"]];
    }
    
    // Set name
    NSString *nameString = [self.tribe objectForKey:kVYBTribeNameKey];
    CGSize nameSize = [nameString boundingRectWithSize:CGSizeMake(144.0f, CGFLOAT_MAX)
                                               options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0f]}
                                               context:nil].size;
    [nameButton setTitle:[self.tribe objectForKey:kVYBTribeNameKey] forState:UIControlStateNormal];
    [nameButton setTitle:[self.tribe objectForKey:kVYBTribeNameKey] forState:UIControlStateHighlighted];
    
    [nameButton setFrame:CGRectMake( 60.0f, 17.0f, nameSize.width, nameSize.height)];
    
}


#pragma mark - ()

+ (CGFloat)heightForCell {
    return 67.0f;
}


/* Inform delegate that a user image or name was tapped */
- (void)didTapTribeButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapTribeButton:)]) {
        [self.delegate cell:self didTapTribeButton:self.tribe];
    }
}

/* Inform delegate that the follow button was tapped */
- (void)didTapVybeButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapVybeButton:)]) {
        [self.delegate cell:self didTapVybeButton:self.tribe];
    }
}


@end
