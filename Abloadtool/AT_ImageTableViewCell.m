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
    self.backgroundColor = [UIColor whiteColor];
    self.imageView.backgroundColor = [UIColor yellowColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    self.textLabel.backgroundColor = [UIColor greenColor];
    self.detailTextLabel.backgroundColor = [UIColor blueColor];
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView cancelImageDownloadTask];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellOffset = (self.frame.size.height - 50) / 2;
    
    self.imageView.frame = CGRectMake(5, cellOffset, 75, 50);
    self.imageView.layer.masksToBounds = YES;

    self.textLabel.frame = CGRectMake(85, cellOffset, self.frame.size.width - 90, self.frame.size.height/2 - cellOffset);
    
    self.detailTextLabel.frame = CGRectMake(85, self.frame.size.height/2, self.frame.size.width - 90, self.frame.size.height/2 - cellOffset);
}

@end
