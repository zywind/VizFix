//
//  VFGazeSample.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/22/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface VFGazeSample :  NSManagedObject  
{
	NSPoint location;
}

/*!
 This property is only for internal use. You should use property location instead.
 */
@property (nonatomic, retain) NSString * locationAsString;
/*!
 A required property. It uses an NSPoint object to indicates the gaze sample location.
 */
@property (nonatomic, assign) NSPoint location;
/*!
 This property is only for internal use. You should use property location instead.
 */
@property (nonatomic, assign) NSPoint primitiveLocation;
/*!
 A required property. It indicates whether this gaze sample is valid or not. 
 Though it is of NSNumber type, you should instead use a BOOL value and wrap it in a NSNumber object.
 */
@property (nonatomic, retain) NSNumber * valid;
/*!
 An optional property.
 */
@property (nonatomic, retain) NSNumber * pupilDiameter;
/*!
 An optional property.
 */
@property (nonatomic, retain) NSNumber * yEyeOffset;
/*!
 An optional property.
 */
@property (nonatomic, retain) NSNumber * focusRange;
/*!
 A required property. Represents the time (ms) this gaze sample is recorded.
 */
@property (nonatomic, retain) NSNumber * time;
/*!
 An optional property.
 */
@property (nonatomic, retain) NSNumber * xEyeOffset;

@end