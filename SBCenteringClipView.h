/********************************************************************
 File:  SBCenteringClipView.h
 
 Created: 1/27/10
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

// Note: This file is created based on the code documented here:
// http://www.bergdesign.com/developer/index_files/88a764e343ce7190c4372d1425b3b6a3-0.html

#import <Cocoa/Cocoa.h>


@interface SBCenteringClipView : NSClipView {
	NSPoint _lookingAt; // the proportion up and across the view, not coordinates.
}

-(void)centerDocument;

@end
