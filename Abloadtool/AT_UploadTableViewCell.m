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

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellOffset         = (self.bounds.size.height -50) / 2;

    self.imageView.frame       = CGRectMake(10, cellOffset                  , 75                              , 50);
    self.textLabel.frame       = CGRectMake(95, cellOffset                  , self.bounds.size.width -100 -105, self.bounds.size.height/2 -cellOffset);
    self.detailTextLabel.frame = CGRectMake(95, self.bounds.size.height/2   , self.bounds.size.width -100     , self.bounds.size.height/2 -cellOffset);
    self.progressView.frame    = CGRectMake(95, self.bounds.size.height/2 -1, self.bounds.size.width -100     , 2);
}


@end
