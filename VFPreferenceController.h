/********************************************************************
 File:  VFPreferenceController.h
 
 Created: 3/9/10
 Modified: 7/15/10
 
 Author: Yunfeng Zhang
 Cognitive Modeling and Eye Tracking Lab
 CIS Department
 University of Oregon
 
 Funded by the Office of Naval Research & National Science Foundation.
 Primary Investigator: Anthony Hornof.
 
 Copyright (c) 2010 by the University of Oregon.
 ALL RIGHTS RESERVED.
 
 Permission to use, copy, and distribute this software in
 its entirety for non-commercial purposes and without fee,
 is hereby granted, provided that the above copyright notice
 and this permission notice appear in all copies and their
 documentation.
 
 Software developers, consultants, or anyone else who wishes
 to use all or part of the software or its documentation for
 commercial purposes should contact the Technology Transfer
 Office at the University of Oregon to arrange a commercial
 license agreement.
 
 This software is provided "as is" without expressed or
 implied warranty of any kind.
********************************************************************/

#import <Cocoa/Cocoa.h>

extern NSString * const VFDistanceGuideSizeKey;
extern NSString * const VFFixationColorKey;
extern NSString * const VFDistanceGuideColorKey;
extern NSString * const VFUncorrectedFixationColorKey;

@interface VFPreferenceController : NSWindowController {
	IBOutlet NSTextField *AOISizeTextField;
    IBOutlet NSColorWell *AOIColorWell;
	IBOutlet NSColorWell *FixationColorWell;
    IBOutlet NSColorWell *UncorrectedFixationColorWell;
}

@end
