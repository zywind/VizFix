//
//  VFInsertHelper.m
//  VizFix
//
//  Created by Yunfeng Zhang on 8/17/12.
//
//

#import "VFInsertHelper.h"
#import "VFVisualStimulusFrame.h"

@implementation VFInsertHelper

- (id)initWithMOC:(NSManagedObjectContext *)anMOC
{
    self = [super init];
	if (self) {
		moc = anMOC;
	}
    return self;
}

- (void)insertStillVisualStimulusID:(NSString *)ID label:(NSString *)label template:(VFVisualStimulusTemplate *)template start:(int)startTime end:(int)endTime location:(NSPoint)point
{
    VFVisualStimulus *vs = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulus" inManagedObjectContext:moc];
    vs.ID = ID;
    vs.template = template;
    vs.startTime = [NSNumber numberWithInt:startTime];
    vs.endTime = [NSNumber numberWithInt:endTime];
    
    if (label) {
        vs.label = label;
    }
    
    VFVisualStimulusFrame *frame = [NSEntityDescription insertNewObjectForEntityForName:@"VisualStimulusFrame"															   inManagedObjectContext:moc];
    frame.startTime = vs.startTime;
    frame.endTime = vs.endTime;
    frame.location = point;
    
    [vs addFramesObject:frame];
}

@end
