//
//  AT_UploadTableViewCell.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 08.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_UploadTableViewCell.h"

@implementation AT_UploadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self addSubview:self.progressView];
    
    [self.marked removeFromSuperview];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellOffset         = (self.bounds.size.height -50) / 2;
    CGFloat cellWidth          = self.bounds.size.width -self.safeAreaInsets.left -self.safeAreaInsets.right;

    self.imageView.frame       = CGRectMake(10, cellOffset                  , 75                  , 50);
    self.textLabel.frame       = CGRectMake(95, cellOffset                  , cellWidth -100 -105, self.bounds.size.height/2 -cellOffset);
    self.detailTextLabel.frame = CGRectMake(95, self.bounds.size.height/2   , cellWidth -100     , self.bounds.size.height/2 -cellOffset);
    self.progressView.frame    = CGRectMake(95 +self.safeAreaInsets.left, self.bounds.size.height/2 -1, cellWidth -100     , 2);
}


@end
