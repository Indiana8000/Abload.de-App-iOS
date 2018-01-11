//
//  AT_UploadTableViewCell.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 08.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_UploadTableViewCell.h"

@implementation AT_UploadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    // Init Cell
    self.backgroundColor = [UIColor whiteColor];
    
    // Init Image
    //self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // Init Text
    //self.textLabel.backgroundColor = [UIColor greenColor];
    //self.detailTextLabel.backgroundColor = [UIColor blueColor];
    
    // Progress
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self addSubview:self.progressView];

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
    
    self.imageView.frame = CGRectMake(10, cellOffset, 75, 50);
    self.imageView.layer.masksToBounds = YES;
    
    self.textLabel.frame = CGRectMake(95, cellOffset, self.frame.size.width - 105, self.frame.size.height/2 - cellOffset);
    
    self.detailTextLabel.frame = CGRectMake(95, self.frame.size.height/2, self.frame.size.width - 105, self.frame.size.height/2 - cellOffset);
    
    self.progressView.frame = CGRectMake(95, self.frame.size.height/2, self.frame.size.width - 105, self.frame.size.height/2 - cellOffset);
}



@end
