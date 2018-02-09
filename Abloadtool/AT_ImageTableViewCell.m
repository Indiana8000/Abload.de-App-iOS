//
//  AT_ImageTableViewCell.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 08.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ImageTableViewCell.h"

@implementation AT_ImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    // Init Cell
    self.backgroundColor = [UIColor whiteColor];
    
    // Init Image
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // Init Text
    self.dateTextLabel = [[UILabel alloc] init];
    self.dateTextLabel.textAlignment = NSTextAlignmentRight;
    self.dateTextLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.dateTextLabel];
    
    // Debug
    //self.textLabel.backgroundColor = [UIColor greenColor];
    //self.detailTextLabel.backgroundColor = [UIColor blueColor];
    //self.dateTextLabel.backgroundColor = [UIColor yellowColor];

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView cancelImageDownloadTask];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellOffset = (self.frame.size.height - 50) / 2;
    
    self.imageView.frame = CGRectMake(10, cellOffset, 50, 50);
    self.imageView.layer.masksToBounds = YES;

    self.textLabel.frame = CGRectMake(70, cellOffset, self.frame.size.width - 75 - 105, self.frame.size.height/2 - cellOffset);
    self.dateTextLabel.frame = CGRectMake(self.frame.size.width - 105, cellOffset , 100, self.frame.size.height/2 - cellOffset);
    //[self.dateTextLabel setAdjustsFontSizeToFitWidth:YES];

    self.detailTextLabel.frame = CGRectMake(70, self.frame.size.height/2, self.frame.size.width - 75, self.frame.size.height/2 - cellOffset);
}

@end
