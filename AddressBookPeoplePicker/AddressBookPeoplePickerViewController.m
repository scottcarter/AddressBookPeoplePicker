//
//  AddressBookPeoplePickerViewController.m
//  AddressBookPeoplePicker
//
//  Created by Scott Carter on 5/4/13.
//

#import "AddressBookPeoplePickerViewController.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


/*
 Description:
 
 Demonstration of using the Address Book People Picker as well as using a callback for Address Book.
 
 We show how to implement the People Picker with the ability to edit existing contacts or
 create new contacts.  Two methods are shown.   
 
 Method 1
 ============
 The first method (must uncomment the define for PERSON_VIEW_CONTROLLER_METHOD1 below)
 is based on the nice blog article by Scott Sherwood at:
 
 http://www.scott-sherwood.com/ios5-removing-the-cancel-button-on-abpeoplepickernavigationcontroller/
 
 I've corrected the example to fix an issue with hitting the Cancel button while editing.
 
 Clicking Cancel in the corrected example will dismiss the entire People Picker.  There was no way to simply
 stop editing mode without also committing any changes that may have been made.
 
 
 Method 2
 =============
 The second method (comment out the define for PERSON_VIEW_CONTROLLER_METHOD1 below) is a modification
 to Scott Sherwood's approach.  Here we manually put up the ABPersonViewController in the protocol method
 peoplePickerNavigationController:shouldContinueAfterSelectingPerson:
 
 This allows me to simplify the code and not worry about modifying the navigation item buttons for the
 ABPersonViewController view.

 The issue I noted with this method is that the information in the ABPeoplePickerNavigationController view
 (names) is not automatically updated when a name is edited (and user clicks Done).   There is no public API
 exposed for performing a refresh.   What I do here is to perform a dummy save when I detect a change in the 
 Address Book.  This dummy Address Book save will force a refresh of the People Picker table view.
 
 */


#pragma mark -



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Private Interface
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
@interface AddressBookPeoplePickerViewController () <ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate, ABNewPersonViewControllerDelegate, UINavigationControllerDelegate>

// ==========================================================================
// Properties
// ==========================================================================
//
#pragma mark -
#pragma mark Properties

@property(strong,nonatomic) ABPeoplePickerNavigationController *picker;

// We register a callback method for Address Book changes.  This variable will keep track of whether
// the callback fired.  The callback will only set this variable however when we the ABPersonViewController
// is in view.  More details in comments in navigationController:didShowViewController:animated:
@property (nonatomic) BOOL addressBookCallbackFired;

// In navigationController:didShowViewController:animated: we track whether the ABPersonViewController is in view.
// Used by Address Book callback.
@property (nonatomic) BOOL inPersonView;

@property (nonatomic) ABAddressBookRef addressBook_cf;

@end



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                    Implementation
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
#pragma mark -
@implementation AddressBookPeoplePickerViewController

// ==========================================================================
// Constants and Defines
// ==========================================================================
//
#pragma mark -
#pragma mark Constants and Defines


// Providing 2 methods of presenting person view controller.  See Description section at top of file.
//
// #define PERSON_VIEW_CONTROLLER_METHOD1 1



// ==========================================================================
// Instance variables.  Could also be in interface section.
// ==========================================================================
//
#pragma mark -
#pragma mark Instance variables

// None


// ==========================================================================
// Synthesize public properties
// ==========================================================================
//
#pragma mark -
#pragma mark Synthesize public properties

// None


// ==========================================================================
// Synthesize private properties
// ==========================================================================
//
#pragma mark -
#pragma mark Synthesize private properties

@synthesize picker = _picker;

@synthesize addressBookCallbackFired = _addressBookCallbackFired;

@synthesize inPersonView = _inPersonView;

@synthesize addressBook_cf = _addressBook_cf;



// ==========================================================================
// Getters and Setters
// ==========================================================================
//
#pragma mark -
#pragma mark Getters and Setters

// None


// ==========================================================================
// Actions
// ==========================================================================
//
#pragma mark -
#pragma mark Actions


// Action for our Contacts button
- (IBAction)contactsAction {
    
    self.addressBookCallbackFired = NO;
    self.inPersonView = NO;
    
    // We create an Address Book instance here and release it in peoplePickerNavigationCancel:
    // The instance is used to register and unregister an Address Book callback in several places.
    if(!self.addressBook_cf){
        self.addressBook_cf = ABAddressBookCreate();
    }
    

    // Register a callback to receive notifications when the Address Book database is modified.
    //
    // Don't pass this address book instance into addressBook property of ABPeoplePickerNavigationController or else
    // callback wont function properly.
    ABAddressBookRegisterExternalChangeCallback (self.addressBook_cf, addressBookExternalChangeCallback, (__bridge void *)(self));

    
    self.picker =
    [[ABPeoplePickerNavigationController alloc] init];
    
    
    // When implementing UINavigationControllerDelegate protocol so that we can adjust navigation buttons,
    // we need to use setDelegate:self in addition to setPeoplePickerDelegate:self
    //
    [self.picker setPeoplePickerDelegate:self];
    [self.picker setDelegate:self];
    
    [self presentViewController:self.picker animated:YES completion:NULL];
}







// ==========================================================================
// Initializations
// ==========================================================================
//
#pragma mark -
#pragma mark Initializations



- (void)viewDidLoad
{
    [super viewDidLoad];
    

    
#ifdef PERSON_VIEW_CONTROLLER_METHOD1
    NSLog(@"Method 1 selected");
#else
    NSLog(@"Method 2 selected");
#endif
    
    
}




// ==========================================================================
// Protocol methods
// ==========================================================================
//
#pragma mark -
#pragma mark Protocol methods

#pragma mark -
#pragma mark Protocol methods for UINavigationControllerDelegate


// Sent to the receiver just after the navigation controller displays a view controller’s view and navigation item properties.
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
 
    // ABPersonViewController
    if([navigationController isKindOfClass:[ABPeoplePickerNavigationController class]]
       && [viewController isKindOfClass:[ABPersonViewController class]]){
        NSLog(@"navigationController:didShowViewController:animated:   - ABPersonViewController");
        
        self.inPersonView = YES;
    }
    
    
    
    // ABPeoplePickerNavigationController
    else if([navigationController isKindOfClass:[ABPeoplePickerNavigationController class]]){
        NSLog(@"navigationController:didShowViewController:animated:   - ABPeoplePickerNavigationController");
        
        self.inPersonView = NO;

#ifdef PERSON_VIEW_CONTROLLER_METHOD1
        
#else
        // For Method 2, we perform a dummy save to refresh the People Picker view in the event
        // that our Address Book callback had fired (record had changed).
        //
        // This works for iOS 5.1 and iOS 6.1, but 5.1 has a little quirk.  The save we do below
        // will queue up an execution of the callback when the callback is eventually registered (even though a callback
        // is not registered at the time of the save).  We mitigate this to a large extent with the use of the
        // flag self.inPersonView.   The callback will only ever set the flag self.addressBookCallbackFired if
        // we are in Person View mode.
        //
        //
        // There is a slight performance impact when we do the dummy save, but this only occurs
        // one time after a record change.   We lessen the impact of this by performing the save in
        // this method rather than navigationController:willShowViewController:animated:  If we did the save
        // in the latter, the user would notice a slight delay when clicking the "All Contacts" back button
        // when returning to the People Picker after a record change.
        //
        // By doing the save in this method, there is no delay when using the back button and the user will
        // only notice any activity due to the save if the name itself is changed and the table refreshes
        // while in view.
        //
        //
        // Another issue with iOS 5.1 is that the callback is called multiple times for one change event.  See:
        // http://stackoverflow.com/questions/10096480/abaddressbookregisterexternalchangecallback-called-several-times
        //
        // The effect of this is that our use of self.inPersonView can be occasionally defeated and an extra dummy save
        // issued when not needed (not really a big issue).   How can this happen?
        //
        // Consider the following scenario:
        // Edit a record & save with Done
        // Switch to People Picker
        // Switch back quickly to Person View
        // Spurious callbacks occur and set self.addressBookCallbackFired=YES since self.inPersonView=YES
        // Switch back to People Picker and unnecessary dummy save occurs.
        //
        //
        if(self.addressBookCallbackFired){
            NSLog(@"addressBook callback fired");
            
            // Unregister the Address Book callback prior to our dummy save.
            ABAddressBookUnregisterExternalChangeCallback (self.addressBook_cf, addressBookExternalChangeCallback, (__bridge void *)(self));
            
            // Only the callback firing will set this flag to YES.  Unfortuately with iOS 5.1 the
            // callback will be called after the save we do below (when we register the callback),
            // even though the callback isn't registered at the time of the save.
            [self setAddressBookCallbackFired:NO];
            
            
            // Dummy AddressBook save to cause People Picker to refresh
            CFErrorRef error_cf = NULL;
            
            ABAddressBookRef addressBook_cf = ABAddressBookCreate();
            
            ABAddressBookSave(addressBook_cf,&error_cf);
            
            if(addressBook_cf){
                CFRelease(addressBook_cf);
            }
            
            // Register the Address Book callback again.
            ABAddressBookRegisterExternalChangeCallback (self.addressBook_cf, addressBookExternalChangeCallback, (__bridge void *)(self));
        }
        else {
            NSLog(@"addressBook callback had not fired");
        }
        
        
#endif
        
        
     }
    
    

}


// Sent to the receiver just before the navigation controller displays a view controller’s view and navigation item properties.
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    
    // Setup the ABPeoplePicker controls here to get rid of he forced cancel button on the right hand side
    // but you also then have to handle other views it pushes on to ensure they have correct buttons
    // shown at the correct time.
    
    
    // First method manipulates navigation buttons on ABPersonViewController in addition to ABPeoplePickerNavigationController
    //
    // Second method only manipulates buttons on ABPeoplePickerNavigationController
    //
    // ABPersonViewController
    if([navigationController isKindOfClass:[ABPeoplePickerNavigationController class]]
       && [viewController isKindOfClass:[ABPersonViewController class]]){
        NSLog(@"navigationController:willShowViewController:animated:   - ABPersonViewController");
        
#ifdef PERSON_VIEW_CONTROLLER_METHOD1
        // Replace the Cancel button with a custom Edit button that calls personViewEditPerson:
        navigationController.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(personViewEditPerson:)];
        
        navigationController.topViewController.navigationItem.leftBarButtonItem = nil;
#endif
    }
    
    
    
    // ABPeoplePickerNavigationController
    else if([navigationController isKindOfClass:[ABPeoplePickerNavigationController class]]){
        NSLog(@"navigationController:willShowViewController:animated:   - ABPeoplePickerNavigationController");
        
        // Replace the Cancel button with a custom Add button that calls peoplePickerNavigationAddPerson:
        navigationController.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(peoplePickerNavigationAddPerson:)];
        
        // Replace the Groups button (may not be present) with a custom Cancel button that calls peoplePickerNavigationCancel:
        navigationController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(peoplePickerNavigationCancel:)];
    }
    
    
    
}


#pragma mark -
#pragma mark Protocol methods for  ABPeoplePickerNavigationControllerDelegate

// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    NSLog(@"peoplePickerNavigationController:shouldContinueAfterSelectingPerson:");
    
    // First method allows ABPeoplePickerNavigationController to present ABPersonViewController
    //
#ifdef PERSON_VIEW_CONTROLLER_METHOD1
    return YES;  // YES to continue and show details for selected person
    
    
    
    // Second method presents ABPersonViewController manually
    //
#else 
    ABPersonViewController *view = [[ABPersonViewController alloc] init];
    
    view.personViewDelegate = self;
    view.displayedPerson = person; // Assume person is already defined.
    view.allowsEditing = YES;
    view.allowsActions = YES;
        
    [peoplePicker pushViewController:view animated:YES];
    
	return NO;
#endif
    
}


// Does allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    NSLog(@"peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier:");
    
	return YES;
}


// Dismisses the people picker and shows the application when users tap Cancel.
//
// Since we implement the ABPeoplePickerNavigationControllerDelegate protocol, we need to implement this method
// to avoid compiler warnings.
//
// We replace the default Cancel button and will end up calling peoplePickerNavigationCancel:
// instead of this method, so the call to dismissViewControllerAnimated is not needed here.
//
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
    NSLog(@"peoplePickerNavigationControllerDidCancel:");
    
	//[self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark -
#pragma mark Protocol methods for ABPersonViewControllerDelegate

// Does allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    NSLog(@"personViewController:shouldPerformDefaultActionForPerson:property:identifier:");
    
	return YES;
}



#pragma mark -
#pragma mark Protocol methods for ABNewPersonViewControllerDelegate

// Called when the user selects Done or Cancel. If the new person was saved, person will be
// a valid person that was saved into the Address Book. Otherwise, person will be NULL.
// It is up to the delegate to dismiss the view controller.
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person{
    NSLog(@"newPersonViewController:didCompleteWithNewPerson:");
    
    [newPersonView dismissViewControllerAnimated:YES completion:NULL];
}





// ==========================================================================
// Class methods
// ==========================================================================
//
#pragma mark -
#pragma mark Class methods

// None


// ==========================================================================
// Instance methods
// ==========================================================================
//
#pragma mark -
#pragma mark Instance methods


#pragma mark -
#pragma mark Instance methods - Person View


// Following ABPersonViewController related methods only needed for method 1
//
#ifdef PERSON_VIEW_CONTROLLER_METHOD1

// Called when Done button clicked.
// Turn off editing mode and put up Edit button.
- (void)personViewDone:(id)sender{
    NSLog(@"personViewDone:");
    
    [self.picker.topViewController setEditing:NO animated:YES];
    self.picker.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(personViewEditPerson:)];
}

// Called when Edit button clicked.
// Set editing mode and put up Done and Cancel buttons.
- (void)personViewEditPerson:(id)sender{
    NSLog(@"personViewEditPerson:");
    
    [self.picker.topViewController setEditing:YES animated:YES];
    
    self.picker.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(personViewDone:)];
    
    self.picker.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(personViewCancel:)];
}


// Called when Cancel button clicked while in Edit mode.
- (void)personViewCancel:(id)sender{
    NSLog(@"personViewCancel:");
    
    
    // Here we dismiss the People Picker.  If we simply set editing mode to NO, any changes made are committed.
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

#endif



#pragma mark -
#pragma mark Instance methods - People Picker


// Called when our custom Add button clicked
//
// Present ABNewPersonViewController in a new navigation controller.
- (void)peoplePickerNavigationAddPerson:(id)sender{
    NSLog(@"peoplePickerNavigationAddPerson:");
    
    ABNewPersonViewController *view = [[ABNewPersonViewController alloc] init];
    view.newPersonViewDelegate = self;
    
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:view];
    [self.picker presentViewController:nc animated:YES completion:NULL];
}


// Called when our custom Cancel button clicked.   Dismiss the People picker.
- (void)peoplePickerNavigationCancel:(id)sender{
    NSLog(@"peoplePickerNavigationCancel:");
    
    // Done with Address Book.  Unregister the callback and release our instance.
    ABAddressBookUnregisterExternalChangeCallback (self.addressBook_cf, addressBookExternalChangeCallback, (__bridge void *)(self));
    
    if(self.addressBook_cf){
        CFRelease(self.addressBook_cf);
        self.addressBook_cf = NULL;
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}





// ==========================================================================
// C methods
// ==========================================================================
//


#pragma mark -
#pragma mark C methods


// Callback invoked when any Address Book changes are detected.
//
// Method used to set addressBookCallbackFired flag for use by navigationController:didShowViewController:animated:
//
void addressBookExternalChangeCallback (ABAddressBookRef addressBook,
                                               CFDictionaryRef info,
                                               void *context
                                               )
{
    AddressBookPeoplePickerViewController *controller = (__bridge AddressBookPeoplePickerViewController *)context;
    
    // If we are in People Picker view, we ignore address book callbacks.
    if(!controller.inPersonView){
        return;
    }

    NSLog(@"MyAddressBookExternalChangeCallback");
    
    [controller setAddressBookCallbackFired:YES];
    
}




@end









