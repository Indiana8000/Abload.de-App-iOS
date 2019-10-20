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
    
    self.canbeSelected                             = NO;
    self.isSelected                                = NO;

    if (@available(iOS 13.0, *)) {
        self.backgroundColor                           = [UIColor systemBackgroundColor];
    } else {
        self.backgroundColor                           = [UIColor whiteColor];
    }
    self.imageView.layer.masksToBounds             = YES;
    self.imageView.backgroundColor                 = [UIColor clearColor];
    self.imageView.contentMode                     = UIViewContentModeScaleAspectFit;
    self.textLabel.adjustsFontSizeToFitWidth       = YES;
    self.detailTextLabel.adjustsFontSizeToFitWidth = NO;
    
    self.dateTextLabel                             = [[UILabel alloc] init];
    self.dateTextLabel.textAlignment               = NSTextAlignmentRight;
    self.dateTextLabel.adjustsFontSizeToFitWidth   = YES;
    [self addSubview:self.dateTextLabel];
    
    self.marked                                    = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_deselected"]];
    [self addSubview:self.marked];

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
    CGFloat cellWidth          = self.bounds.size.width -self.safeAreaInsets.left -self.safeAreaInsets.right;
    
    self.imageView.frame       = CGRectMake(10            , cellOffset              , 50                , 50);
    self.textLabel.frame       = CGRectMake(70            , cellOffset              , cellWidth -75 -105, self.bounds.size.height/2 -cellOffset);
    self.dateTextLabel.frame   = CGRectMake(cellWidth -105 +self.safeAreaInsets.left, cellOffset              , 100               , self.bounds.size.height/2 -cellOffset);
    self.detailTextLabel.frame = CGRectMake(70            , self.frame.size.height/2, cellWidth -75     , self.bounds.size.height/2 -cellOffset);

    if(self.canbeSelected) {
        if(self.isSelected) {
            self.marked.image = [UIImage imageNamed:@"photo_selected"];
        } else {
            self.marked.image = [UIImage imageNamed:@"photo_deselected"];
        }
        self.marked.frame          = CGRectMake(45            , cellOffset +30          , 20                , 20);
    } else {
        self.marked.frame          = CGRectMake(0, 0, 0, 0);
    }
}


@end
