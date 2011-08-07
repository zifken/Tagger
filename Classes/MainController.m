//
//  Controller.m
//  VGTagger
//
//  Created by Bilal Syed Hussain on 05/07/2011.
//  Copyright 2011 St. Andrews KY16 9XW. All rights reserved.
//

#import "MainController.h"
#import "Tags.h"
#import "MP4Tags.h"
#import "VgmdbController.h"
#import "DisplayController.h"
#import "FileSystemNode.h"
#import "NSMutableArray+Stack.h"
#import "ImageAndTextCell.h"
#import "FileSystemNodeCollection.h"
#import "RenamingFilesController.h"

#import "DDLog.h"
static const int ddLogLevel = LOG_LEVEL_INFO;
static const NSArray *predefinedDirectories;

@interface MainController()  

- (void) initDirectoryTable;
- (void) setPopupMenuIcons;

- (void) backForwordDirectoriesCommon;

- (NSString *)stringFromFileSize:(NSInteger)size;

/// Change the current directory to the clicked entries
- (IBAction) onClick:(id)sender;
@end

@implementation MainController
@synthesize window, directoryStack, currentNodes,forwardStack, selectedNodeindex, parentNodes, table;


#pragma mark -
#pragma mark Table Methods 

- (IBAction) onClick:(id)sender
{
	// code to make cells that are editable go to edit
	NSEvent *currentEvent = [NSApp currentEvent];
	NSInteger column = [table clickedColumn];
	NSInteger row = [table clickedRow];
	NSCell *theCell = [table preparedCellAtColumn:column row:row];
	NSRect cellFrame = [table frameOfCellAtColumn:column row:row];
	NSUInteger hitTestResult = [theCell hitTestForEvent:currentEvent inRect:cellFrame ofView:table];
	
	if ( ( hitTestResult & NSCellHitEditableTextArea ) != NSCellHitEditableTextArea ) return;
	if ([[[table tableColumns] objectAtIndex:column] isEditable]){
		[table editColumn:column row:row withEvent:currentEvent select:YES];	
		return;
	}
	
	NSArray *children = [[directoryStack lastObject] children];
	FileSystemNode *node = [children objectAtIndex:row];
	DDLogVerbose(@"onClick selected %@", node);
	if ([node isDirectory]){
		[directoryStack addObject:node];
		[table reloadData];
		[parentNodes insertObject:node atIndex:0];
		[popup insertItemWithTitle:[node displayName] atIndex:0];
		[[popup itemAtIndex:0] setImage:[node icon]];
		self.selectedNodeindex = [NSNumber numberWithInteger:0];
		// clear the forward stack since it would not make sense any more
		[forwardStack removeAllObjects];
	}	
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView 
{
    return [[[directoryStack lastObject] children] count];
}


- (NSString *)stringFromFileSize:(NSInteger)size
{
	double floatSize = size;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%zd bytes",size]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1lf KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1lf MB",floatSize]);
	floatSize = floatSize / 1024;	
	return([NSString stringWithFormat:@"%1.1lf GB",floatSize]);
}

- (id)          tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
					  row:(NSInteger)rowIndex 
{
	NSArray *children = [[directoryStack lastObject] children];
	FileSystemNode *node = [children objectAtIndex:rowIndex];
	
	
	if ( [[aTableColumn identifier] isEqualToString:@"filename"] ){
		return [node displayName];
	}else if ([[aTableColumn identifier] isEqualToString:@"size"]){
		return [self stringFromFileSize:[[node size] integerValue]];
	}else if ([[aTableColumn identifier] isEqualToString:@"trackPair"]){
		return [NSString stringWithFormat:@"%@ of %@",node.tags.track, node.tags.totalTracks];
	}else if ([[aTableColumn identifier] isEqualToString:@"discPair"]){
		return [NSString stringWithFormat:@"%@ of %@",node.tags.disc, node.tags.totalDiscs];
	}else if ([node isDirectory]){
		return @"";
	}
	
	return [node.tags valueForKey:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	
	NSArray *children = [[directoryStack lastObject] children];
	FileSystemNode *node = [children objectAtIndex:rowIndex];
	
	if ([[aTableColumn identifier] isEqualToString:@"filename"]) return;
	[node.tags setValue:anObject forKey:[aTableColumn identifier]];
}

// Shows the icon for the file
- (void)tableView:(NSTableView *)tableView 
  willDisplayCell:(id)cell 
   forTableColumn:(NSTableColumn *)tableColumn
			  row:(NSInteger)rowIndex
{
	if ([[tableColumn identifier] isEqualToString:@"filename"]){
		NSArray *children = [[directoryStack lastObject] children];
		NSImage *icon = [[children objectAtIndex:rowIndex] icon];
		[icon setSize:NSMakeSize(16, 16)];
		[(ImageAndTextCell*)cell setImage: icon];		
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	const NSInteger selectedRow = [table selectedRow];

	if (selectedRow == -1){
		self.currentNodes.tagsArray = nil;
		
	}else{
		self.currentNodes.tagsArray = [[[directoryStack lastObject] children] 
									   objectsAtIndexes:[table selectedRowIndexes]];
	}
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	DDLogVerbose(@"headerClicked");
}

#pragma mark -
#pragma mark Directory Manipulation Methods

-(IBAction) goToParentMenu:(id)sender
{
	if ([parentNodes count] >=2){
		self.selectedNodeindex = [NSNumber numberWithInt:1];
		[self goToParent:popup];	
	}
}


-(IBAction) goToParent:(id)sender
{
	DDLogVerbose(@"i:%@ pN:%@", selectedNodeindex, [parentNodes objectAtIndex:[selectedNodeindex intValue]]);
	int index = [selectedNodeindex intValue];
	if (index == 0) {
		return;
	}
	
	// remove all the child elements
	int i;
	for (i =0; i < index; ++i) {
		[parentNodes removeObjectAtIndex:0];
		[popup  removeItemAtIndex:0];
	}
	
	//Refresh the gui
	self.selectedNodeindex = [NSNumber numberWithInt:0];
	
	[directoryStack addObject:[parentNodes objectAtIndex:0]];
	DDLogInfo(@"directoryStack %@", directoryStack);
	[table deselectAll:self];
	[table reloadData];
}

- (void) setPopupMenuIcons
{
	int i =0; 
	for (i=0; i< [popup numberOfItems]; ++i) {
		[[popup itemAtIndex:i] setImage:[[parentNodes objectAtIndex:i] icon]];
	}
}

- (IBAction) open:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
    if ([op runModal] != NSOKButton) return;
    
	[self goToDirectory:[op URL]];
}

- (void) goToDirectory:(NSURL*)url
{
	DDLogInfo(@"%@ selected", url);
	FileSystemNode *node  = [[FileSystemNode alloc ] initWithURL:url];
	[parentNodes removeAllObjects];
	[parentNodes addObjectsFromArray:[node parentNodes] ];
	
 	[directoryStack addObject:node];
	[table deselectAll:self];
	[table reloadData];
	
	NSInteger popupCount = [popup numberOfItems];
	NSInteger min = MIN([parentNodes count], popupCount);
	DDLogVerbose(@"min:%zu pN:%zu popN:%zu", min, [parentNodes count], popupCount);
	
	// Correct the number of items in the popupmenu
	NSInteger i;
	for (i=min; i < [parentNodes count]; ++i) {
		[popup addItemWithTitle:[[NSNumber numberWithLong:i] stringValue] ];
		DDLogVerbose(@"pN:%zu popN:%zu", [parentNodes count], [popup numberOfItems]);
	}	
	
	for (i=min; i < popupCount; ++i) {
		[popup removeItemAtIndex:0];
	}
	
	for (i=0; i < [popup numberOfItems]; ++i) {
		[[popup itemAtIndex:i] setTitle:[[parentNodes objectAtIndex:i] displayName]];
		[[popup itemAtIndex:i] setImage:[[parentNodes objectAtIndex:i] icon]];
	}	
}

- (IBAction) backForwordDirectories:(id)sender
{
	DDLogVerbose(@"backForwordDirectories");
    NSInteger tag = [[sender cell] tagForSegment:[sender selectedSegment]];
	DDLogVerbose(@"tag :%zd  ds %zd fs %zd", tag,  [directoryStack count],[forwardStack count] );
	
	if (tag == 0){
		[self backDirectories:sender];		
	}else if (tag == 1){
		[self forwordDirectories:sender];
	}
	
}

- (void) backForwordDirectoriesCommon
{
	self.parentNodes = [[directoryStack lastObject] parentNodes];
	DDLogVerbose(@"%@ bf parentNodes %@", [[directoryStack lastObject] displayName], parentNodes);
	
	[self setPopupMenuIcons];
	self.selectedNodeindex = [NSNumber numberWithInt:0];
	DDLogVerbose (@"directoryStack %@", directoryStack);
	[table deselectAll:self];
	[table reloadData];
}

- (IBAction) backDirectories:(id)sender
{
	if ( [directoryStack count] >= 2){
		[forwardStack addObject:[directoryStack pop]];
		[self backForwordDirectoriesCommon];	
	}
}

- (IBAction) forwordDirectories:(id)sender
{
	if ( [forwardStack count] >= 1){
		[directoryStack addObject:[forwardStack pop]];
		[self backForwordDirectoriesCommon];	
	}
}

#pragma mark -
#pragma mark Gui Callback

- (IBAction) goToPredefinedDirectory:(id)sender
{
	[self goToDirectory:[predefinedDirectories objectAtIndex:[sender tag]]];
}

- (IBAction) search:(id)sender
{
	if (vgc == nil){
		vgc = [[VgmdbController alloc] initWithFiles:[[directoryStack lastObject] children]];	
	}else{
		[vgc reset:[[directoryStack lastObject] children]];	
	}
	[NSApp beginSheet: [vgc window]
	   modalForWindow: self.window
		modalDelegate: vgc 
	   didEndSelector: @selector(didEndSheet:returnCode:mainWindow:)
		  contextInfo: self.window];
	[table reloadData];
}

- (IBAction) searchWithSubDirectories:(id)sender
{
	NSMutableArray *nodes = [[NSMutableArray alloc] init ];
	for (FileSystemNode *n in [[directoryStack lastObject] children]) {
		if (n.isDirectory){
			[nodes addObjectsFromArray:n.children];
		}
	}
	
	if (vgc == nil){
		vgc = [[VgmdbController alloc] initWithFiles:nodes];	
	}else{
		[vgc reset:nodes];	
	}
	
	[NSApp beginSheet: [vgc window]
	   modalForWindow: self.window
		modalDelegate: vgc 
	   didEndSelector: @selector(didEndSheet:returnCode:mainWindow:)
		  contextInfo: self.window];
	[table reloadData];
}

- (IBAction) refresh:(id)sender
{
	[[directoryStack lastObject] invalidateChildren];
}

- (IBAction) rename:(id)sender
{
	if (!currentNodes.hasExtenedMetadata) return;
	DDLogInfo(@"rename");
	
	if (rfc)  [rfc release];
	rfc = [[RenamingFilesController alloc] initWithNodes:currentNodes];
		
	[NSApp beginSheet: [rfc window]
	   modalForWindow: self.window
		modalDelegate: rfc 
	   didEndSelector: @selector(didEndSheet:returnCode:result:)
		  contextInfo: [directoryStack lastObject]];
	
}

- (IBAction)revealInFinder:(id)sender
{
	for (FileSystemNode *n in currentNodes.tagsArray) {
		[[NSWorkspace sharedWorkspace] selectFile:[n.URL path] 
								inFileViewerRootedAtPath:nil];
	}
}

- (id)valueForUndefinedKey:(NSString *)key
{
	DDLogError(@"valueForUndefinedKey:%@",key);
	return @"ERROR";
}

#pragma mark -
#pragma mark Windows

- (BOOL)windowShouldClose:(NSNotification *)notification
{
	NSLog(@"bye");
	[window orderOut:self];
	return NO;
}


- (IBAction)reopen:(id)sender
{
	[self showWindow:self];
}

#pragma mark -
#pragma mark Alloc/init

- (void)awakeFromNib
{	
	[self setPopupMenuIcons];
	[table setDoubleAction:@selector(onClick:)];
	[[table tableColumnWithIdentifier:@"filename"] setEditable:false];
	[[table tableColumnWithIdentifier:@"title"] setEditable:true];
	[table setTarget:self];
}

-(void) initDirectoryTable
{
	directoryStack = [[NSMutableArray alloc] init];
	forwardStack   = [[NSMutableArray alloc] init];
	
	NSLog(@"url %@", [[NSUserDefaults standardUserDefaults] URLForKey:@"startUrl"]);
	FileSystemNode *currentDirectory = [[FileSystemNode alloc] initWithURL:
										[[NSUserDefaults standardUserDefaults] URLForKey:@"startUrl"]];
//	FileSystemNode *currentDirectory = [[FileSystemNode alloc] initWithURL:
//										[NSURL fileURLWithPath:[@"~/Movies/add/start/Atelier Meruru OST/" 
//																stringByExpandingTildeInPath]]];
	[directoryStack push:currentDirectory];
	
	currentNodes      = [[FileSystemNodeCollection alloc] init];
	selectedNodeindex = [NSNumber numberWithInt:0];
	parentNodes            = [currentDirectory parentNodes];
	
	DDLogVerbose(@"Staring parentNodes%@", parentNodes);
}

- (id)init
{
    self = [super init];
    if (self) {
		[self initDirectoryTable ];
    }
	
    return self;
}

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:
															 [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]]];	
	[[NSUserDefaults standardUserDefaults]  synchronize];
	
	predefinedDirectories = [[NSArray alloc] initWithObjects:
							 [NSURL fileURLWithPath:[@"/" stringByExpandingTildeInPath] 
										isDirectory:YES],
							 [NSURL fileURLWithPath:[@"~" stringByExpandingTildeInPath]
										isDirectory:YES],
							 [NSURL fileURLWithPath:[@"~/Desktop" stringByExpandingTildeInPath]
										isDirectory:YES],
							 [NSURL fileURLWithPath:[@"~/Downloads" stringByExpandingTildeInPath]
										isDirectory:YES],
							 [NSURL fileURLWithPath:[@"~/Music"stringByExpandingTildeInPath]
										isDirectory:YES],
							 [NSURL fileURLWithPath:[@"~/Movies"stringByExpandingTildeInPath]
										isDirectory:YES],
							 nil];
}

- (void)dealloc
{
    [super dealloc];
}


@end
