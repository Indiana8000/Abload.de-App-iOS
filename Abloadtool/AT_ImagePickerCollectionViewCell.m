//
//  AT_ImagePickerCollectionViewCell.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 22.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ImagePickerCollectionViewCell.h"

@implementation AT_ImagePickerCollectionViewCell
@synthesize isSelected = _isSelected;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.isSelected = NO;
    
    self.imageView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.imageView];
    
    self.marked = [[UIImageView alloc] init];
    [self.contentView addSubview:self.marked];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;

    if(self.isSelected) {
        self.marked.image = [UIImage imageNamed:@"photo_selected"];
    } else {
        self.marked.image = [UIImage imageNamed:@"photo_deselected"];
    }
    self.marked.frame = CGRectMake(self.imageView.bounds.size.width -25, self.imageView.bounds.size.height -25, 20, 20);
}

- (BOOL)isSelected {
    return _isSelected;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    if(self.isSelected) {
        self.marked.image = [UIImage imageNamed:@"photo_selected"];
    } else {
        self.marked.image = [UIImage imageNamed:@"photo_deselected"];
    }
}



@end
