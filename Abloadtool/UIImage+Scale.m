//
//  UIImage+Scale.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 02.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (scale)

static inline double radians (double degrees) {return degrees * M_PI / 180;}

-(UIImage *)scaleToSize:(CGSize)size {
    // Create a bitmap graphics context
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the scaled image in the current context
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // Create a new image from current context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new scaled image
    return scaledImage;
}

-(UIImage *)panToSize:(CGSize)size {
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, 0, size.width, newHeight);
    } else {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake(0, 0, newWidth , size.height );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(CGSizeMake(thumbSize.size.width, thumbSize.size.height));
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}

-(UIImage *)cutToSize:(CGSize)size {
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake( (size.width-newWidth)/2, 0, newWidth, size.height);
    } else {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, (size.height-newHeight)/2, size.width , newHeight );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}


- (UIImage *)thumbnailOfSize:(CGSize)size {
    // Calculate new size with aspection ratio and centered in the target size
    CGRect thumbSize;
    if (self.size.width/self.size.height > size.width/size.height  ) {
        float newHeight = size.width / (self.size.width / self.size.height);
        thumbSize = CGRectMake(0, (size.height-newHeight)/2, size.width, newHeight);
    } else {
        float newWidth = size.height * self.size.width / self.size.height;
        thumbSize = CGRectMake(  (size.width-newWidth)/2 , 0 , newWidth , size.height );
    }
    
    // Create a bitmap graphics context (of the target size)
    // This will also set it as the current context
    UIGraphicsBeginImageContext(size);
    
    // Draw the image in the calculated area
    [self drawInRect:thumbSize];
    
    // Create a new image from current context
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    // Pop the current context from the stack
    UIGraphicsEndImageContext();
    
    // Return our new thumbnail image
    return newThumbnail;
}

-(UIImage *)rotate {
    // Create and Draw.
    UIGraphicsBeginImageContext(self.size);
    [self drawAtPoint:CGPointMake(0, 0)];
    
    // Roteate Context
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (self.imageOrientation == UIImageOrientationDown) {
        //CGContextRotateCTM (context, radians(0));
    } else if (self.imageOrientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(180));
    }
    
    // Create a new image from current context
    UIImage* rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotatedImage;
}



@end
