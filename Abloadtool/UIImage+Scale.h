//
//  UIImage+Scale.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 02.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (scale)

-(UIImage *)scaleToSize:(CGSize)size;
-(UIImage *)panToSize:(CGSize)size;
-(UIImage *)cutToSize:(CGSize)size;

-(UIImage *)thumbnailOfSize:(CGSize)size;
-(UIImage *)fixOrientation;

@end
