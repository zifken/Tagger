//
//  QuickLookTableView.m
//  VGTagger
//
//  Created by Bilal Syed Hussain on 11/08/2011.
//  Copyright 2011 St. Andrews KY16 9XW. All rights reserved.
//

#import "QuickLookTableView.h"
#import "VGTaggerAppDelegate.h"
#import "MainController.h"
#import "FileSystemNode.h"
#import "BHFinderLabelColours.h"

@implementation QuickLookTableView

- (void)keyDown:(NSEvent *)theEvent
{
    NSString* key = [theEvent charactersIgnoringModifiers];
    if([key isEqual:@" "]) {
        [[NSApp delegate] togglePreviewPanel:self];
    } else {
        [super keyDown:theEvent];
    }
}


// Override The row colour with the label colour for only the filename column.
// with nice rounded side if there is a label colour.
- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect;
{
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	if ([selectedRowIndexes containsIndex:row]){
				
		// draw a "dot" of color, similar to what the Finder does, 
		NSInteger labelIndex = BHLabelColorNone;
		if ([[self dataSource] respondsToSelector:@selector(labelColorForRow:)]) {
			labelIndex = [(id)[self dataSource] labelColorForRow:row];
		}
		NSGradient *gradient = [BHFinderLabelColours gradientForLabelIndex:labelIndex];
		
		if (gradient)
		{			
			NSRect rowRect = [self rectOfRow:row];
			NSRect colRect = [self rectOfColumn: [self columnWithIdentifier:@"filename"]];
			rowRect.origin.x   = colRect.origin.x;
			rowRect.size.width = colRect.size.width;
			NSRect gradientRect = 
			NSMakeRect(2, 
					   ([self rowHeight]+[self intercellSpacing].height)*row + 1.0, 
					   20.0, 
					   rowRect.size.height - 2.0);
			NSBezierPath *gradientPath = [NSBezierPath bezierPathWithRoundedRect:gradientRect 
																		 xRadius:9.0 
																		 yRadius:9.0];
			[gradient drawInBezierPath:gradientPath angle:90.0];			
		}		
		[super drawRow:row clipRect:clipRect];	
	}else{
		NSInteger labelIndex= BHLabelColorNone;
		if ([[self dataSource] respondsToSelector:@selector(labelColorForRow:)]) {
			labelIndex = [(id)[self dataSource] labelColorForRow:row];
		}
		
		NSGradient *gradient = [BHFinderLabelColours gradientForLabelIndex:labelIndex];
		
		if (gradient && ![[self selectedRowIndexes] containsIndex:row])
		{
			NSRect rowRect = [self rectOfRow:row];
			NSRect colRect = [self rectOfColumn: [self columnWithIdentifier:@"filename"]];
			rowRect.origin.x   = colRect.origin.x;
			rowRect.size.width = colRect.size.width;
			
			NSRect gradientRect = NSMakeRect(0, 
											 ([self rowHeight]+[self intercellSpacing].height)*row + 1.0, 
											 rowRect.size.width - 4.0, 
											 rowRect.size.height - 2.0);
			NSBezierPath *smallerPath = [NSBezierPath bezierPathWithRoundedRect:gradientRect 
																		xRadius:9.0 
																		yRadius:9.0];
			[gradient drawInBezierPath:smallerPath 
								 angle:90.0];
		}
		
		[super drawRow:row clipRect:clipRect];	
	}
}


- (void) awakeFromNib
{
	// Register to accept filename drag/drop
	[self registerForDraggedTypes:[[self registeredDraggedTypes ] arrayByAddingObject:NSFilenamesPboardType]];

}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Need the delegate hooked up to accept the dragged item(s) into the model
	if ([self delegate]==nil)
	{
		return NSDragOperationNone;
	}
	
	if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType])
	{
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}


// Stop the NSTableView implementation getting in the way
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]){
		return [self draggingEntered:sender];		
	}else{
		return [super draggingUpdated:sender];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard;
	pboard = [sender draggingPasteboard];
	if ([[pboard types] containsObject:NSFilenamesPboardType])
	{
		id delegate = [self delegate];
		NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
		if ([delegate respondsToSelector:@selector(acceptFilenameDrag:)])
		{
			for (id name in filenames) {
				[delegate performSelector:@selector(acceptFilenameDrag:) 
							   withObject:name];
			}
		}
		return YES;
	}
	return [super performDragOperation:sender];
}	


@end
