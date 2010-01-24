//
//  VFView.h
//  VizFix
//
//  Created by Yunfeng Zhang on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFSubTrial.h"
#import "VFVisualStimulus.h"
#import "VFVisualStimulusTemplate.h"
#import "VFVisualStimulusFrame.h"
#import "VFGazeSample.h"
#import "VFSession.h"
#import "VFFixation.h"

@interface VFView : NSClipView {
	IBOutlet NSArrayController *visualStimuliController;
	IBOutlet NSArrayController *visualStimulusFramesController;
	IBOutlet NSArrayController *gazeSampleController;
	IBOutlet NSArrayController *fixationController;

	IBOutlet NSObjectController *sessionController;
}

- (NSArray*)zorderSortDescriptor;
- (void)drawVisualStimulusTemplate:(VFVisualStimulusTemplate *)visualStimulusTemplate;
@end
