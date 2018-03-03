//
//  AT_ImageTableViewCell.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 08.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ImageTableViewCell.h"


@implementation AT_ImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];

    self.backgroundColor                           = [UIColor whiteColor];
    self.imageView.layer.masksToBounds             = YES;
    self.imageView.backgroundColor                 = [UIColor whiteColor];
    self.imageView.contentMode                     = UIViewContentModeScaleAspectFit;
    self.textLabel.adjustsFontSizeToFitWidth       = YES;
    self.detailTextLabel.adjustsFontSizeToFitWidth = NO;
    
    self.dateTextLabel                             = [[UILabel alloc] init];
    self.dateTextLabel.textAlignment               = NSTextAlignmentRight;
    self.dateTextLabel.adjustsFontSizeToFitWidth   = YES;
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

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellOffset         = (self.bounds.size.height -50) / 2;
    
    self.imageView.frame       = CGRectMake(10                          , cellOffset              , 50                             , 50);
    self.textLabel.frame       = CGRectMake(70                          , cellOffset              , self.bounds.size.width -75 -105, self.bounds.size.height/2 -cellOffset);
    self.dateTextLabel.frame   = CGRectMake(self.bounds.size.width - 105, cellOffset              , 100                            , self.bounds.size.height/2 -cellOffset);
    self.detailTextLabel.frame = CGRectMake(70                          , self.frame.size.height/2, self.bounds.size.width -75     , self.bounds.size.height/2 -cellOffset);
}


@end
