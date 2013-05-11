

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
