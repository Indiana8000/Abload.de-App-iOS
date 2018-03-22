//
//  AT_ImagePickerCollectionViewCell.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 22.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AT_ImagePickerCollectionViewCell : UICollectionViewCell
@property UIImageView* imageView;
@property BOOL isSelected;

@property UIImageView* marked;

@end
