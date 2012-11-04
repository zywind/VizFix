//
//  VFInsertHelper.h
//  VizFix
//
//  Created by Yunfeng Zhang on 8/17/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VFVisualStimulusTemplate.h"

@interface VFInsertHelper : NSObject {
	NSManagedObjectContext *moc;
}

- (id)initWithMOC:(NSManagedObjectContext *)anMOC;
- (void)insertStillVisualStimulusID:(NSString *)ID label:(NSString *)label template:(VFVisualStimulusTemplate *)template start:(int)startTime end:(int)endTime location:(NSPoint)point;
@end
