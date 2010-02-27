//
//  VFFixationRegister.h
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 2/3/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VFUtil.h"
#import "VFVisualAngleConverter.h"
#import "VFFixation.h"

@interface VFFixationRegister : NSObject {
	NSManagedObjectContext *moc;
	VFVisualAngleConverter *converter;
	NSArray *visualStimuliArray;
	NSDictionary *customAOIs;
	
	double autoAOIDOV;
}

@property (retain) NSDictionary * customAOIs;
@property double autoAOIDOV;

- (id)initWithMOC:(NSManagedObjectContext *)anMOC;
- (void)registerFixationToClosestAOI:(VFFixation *)aFixation;
- (void)registerAllFixations;
- (void)useVisualStimuliOfCategoriesAsAOI:(NSArray *)categories;

@end
