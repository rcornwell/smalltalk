
Object subclass: 'Switch'
	instanceVariableNames: 'on onAction offAction '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus' 
!

Switch comment:
'I represent a selection setting and actions to take depending on a change in the setting.
 An instance has three attributes: state, which is either on or off; on action; and off action.
 The on and off actions are blocks of code that execute whenever the instance changes state.
 I am typically used as a menu item in conjunction with a SwitchView and a SwitchController.' 
!

! Switch methodsFor: 'initialize-release' !

release
	"Set the on and off actions of the receiver to nil ('no action') in order to
	break possible pointer cycles.  It is sent by Switch deleteDependent: when
	the last dependent has been deleted from the Switch's list of dependents."

	super release.
	onAction <- nil.
	offAction <- nil
! !

! Switch methodsFor: 'dependents access' !

removeDependent: aDependent 
	"If aDependent is the only dependent in the list, the receiver sends  
	Switch release to try to break up possible pointer cycles."

	super removeDependent: aDependent.
	self dependents isEmpty ifTrue: [self release]
! !

! Switch methodsFor: 'state' !

clear
	"Set the state of the receiver to 'off'. If the state of the receiver was 
	previously 'on', then 'self change' is sent. The receiver's off action is 
	NOT executed."

	self isOn
		ifTrue: 
			[on <- false.
			self changed]
!

isOff
	"Answer whether the receiver is set off or not."

	^on not
!

isOn
	"Answer whether the receiver is set on or not."

	^on
!

set
	"Set the state of the receiver to 'on'. If the state of the receiver was 
	previously 'off', then 'self change' is sent. The receiver's on action is 
	NOT executed."

	self isOff
		ifTrue: 
			[on <- true.
			self changed]
!

switch
	"Change the state of the receiver from 'on' to 'off' or from 'off' to 'on' (see turnOn, turnOff)."

	self isOn
		ifTrue: [self turnOff]
		ifFalse: [self turnOn]
!

turnOff
	"Set the state of the receiver to 'off'. If the state of the receiver was 
	previously 'on', then 'self change' is sent and the receiver's off action is 
	executed."

	self isOn
		ifTrue: 
			[on <- false.
			self changed.
			self doAction: offAction]
!

turnOn
	"Set the state of the receiver to 'on'. If the state of the receiver was 
	previously 'off', then 'self change' is sent and the receiver's on action is 
	executed."

	self isOff
		ifTrue: 
			[on <- true.
			self changed.
			self doAction: onAction]
! !

! Switch methodsFor: 'action' !

doAction: anAction 
	"Execute anAction if it is non-nil."

	anAction isNil ifFalse: [anAction value]
!

offAction: anAction 
	"Set the off action of the receiver to anAction."

	offAction <- anAction
!

onAction: anAction 
	"Set the on action of the receiver to anAction."

	onAction <- anAction
! !

! Switch methodsFor: 'private' !

initializeOff

	on <- false. 
	onAction <- nil.
	offAction <- nil
!

initializeOn

	on <- true. 
	onAction <- nil.
	offAction <- nil
! !

! Switch class methodsFor: 'instance creation' !

new
	"Answer an instance of me such that the on and off actions are set to nil
	('no action'), and the state is set to 'off'."

	^self newOff
!

newOff
	"Answer an instance of me such that the on and off actions are set to nil 
	('no action'), and the state is set to 'off'."

	^super new initializeOff
!

newOn
	"Answer an instance of me such that the on and off actions are set to nil 
	('no action'), and the state is set to 'on'."

	^super new initializeOn
! !

Switch subclass: 'OneOnSwitch'
	instanceVariableNames: 'connection'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'
!

OneOnSwitch comment:
'I am a kind of Switch that can be connected to some related object, typically to a collection of my instances.
 When my instance is created, its connection is set to a particular object.
 When the object changes because an Switch it refers to is turned on, an update message is broadcasted. 
 All the connected OneOnSwitches, except the changed one, turn off.
 This allows OneOnSwitches to maintain the constraint that at most one of them will be on at any time.
 OneOnSwitches can thus be made to act like "car radio" switches.'
!

! OneOnSwitch methodsFor: 'initialize-release' !

release

	super release.
	self isConnectionSet ifTrue: [connection removeDependent: self]
! !

! OneOnSwitch methodsFor: 'state' !

turnOn
	"Does nothing if it is already on. If it is not, it is set to 'on', its
	dependents are 	notified of the change, its connection is notified, and
	its action is executed."

	self isOff
		ifTrue: 
			[on <- true.
			self changed.
			self notifyConnection.
			self doAction: onAction]
! !

! OneOnSwitch methodsFor: 'connection' !

connection
	"Answer the object that connects the receiver to other Switches."

	^connection
!

connection: anObject 
	"Set anObject to be the connection among two or more Switches. Make the 
	receiver a dependent of the argument, anObject."

	connection <- anObject.
	connection addDependent: self
!

isConnectionSet
	"Answer whether the receiver is connected to an object that coordinates 
	updates among switches."

	connection isNil
		ifTrue: [^false]
		ifFalse: [^true]
!

notifyConnection
	"Send the receiver's connection (if it exists) the message 'changed: self' in 
	order for the connection to broadcast the change to other objects 
	connected by the connection."
	
	self isConnectionSet ifTrue: [self connection changed: self]
! !

! OneOnSwitch methodsFor: 'updating' !

update: aOneOnSwitch 
	"Does nothing if aOneOnSwitch is identical to this object. If it is not, this 
	object is turned off. This message is sent by the connection (an Object)
	when some related OneOnSwitch (possibly this one) has changed. This
	allows a group of related OneOnSwitches to maintain the constraint that
	at most one will be on at any time."

	self ~~ aOneOnSwitch ifTrue: [self turnOff]
! !

Switch subclass: 'ButtonSwitch'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'
!

ButtonSwitch comment:
'I am a kind of Switch that automaticaly turns off after being turned on.'
!

! ButtonSwitch methodsFor: 'state' !

turnOff
	on <- false.
!

turnOn
	"Simulate a on-off event"
	self doAction: onAction
	self doAction: offAction
! !

! ButtonSwitch class methodsFor: 'instance creation' !

newOn
	self error: 'ButtonSwitches can not be created in on state'.
! !

Controller subclass: 'SwitchController'
	instanceVariableNames: 'selector arguments '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics Windows'
!

SwitchController comment:
'I coordinate the interaction of a Switch, a SwitchView, and input events (user actions, see class Sensor). My instances own a message in the form of a selector and an array of arguments. Whenever the Switch is selected, this message is sent to the Switch. I want control if the cursor is in the view and the red button is pressed.'
!

! SwitchController methodsFor: 'initialize-release' !

initialize
	super initialize.
	selector <- #switch.
	arguments <- Array new: 0
! !

! SwitchController methodsFor: 'accessing' !

addArgument: aValue 
	"Add the argument, aValue, as one of the arguments of the message the 
	receiver sends to its model."

	arguments <- arguments copyWith: aValue
!

arguments
	"Answer the arguments the receiver sends in a message to its receiver."

	^arguments
!

arguments: anArray
	"The argument, anArray, consists of the arguments of the message the 
	receiver sends to its model."

	arguments <- anArray
!

selector
	"Answer the selector the receiver sends in a message to its receiver."

	^selector
!

selector: aSymbol 
	"Set aSymbol to be the selector the receiver sends in a message to its 
	model."

	selector <- aSymbol
! !

! SwitchController methodsFor: 'control' !

controlInitialize
	view indicatorReverse
!

controlTerminate
	view indicatorReverse.
!

sendMessage
	"The receiver consists of a selector and possibly of arguments that should 
	be used to create a message to send to the receiver's model."
	model preform: selector
	"arguments size = 0
		ifTrue: [model perform: selector]
		ifFalse: [model perform: selector withArguments: arguments]"
!

controlActivity
	view indicatorReverse.
	self sendMessage.
	view indicatorReverse.
	Sensor waitNoButton
!

isControlActive
	[ self viewHasCursor ] whileTrue: [
		Sensor anyButtonPressed ifTrue: [ ^ true ].
		Sensor waitMouse.
	].
	^ false
!

isControlWanted
	^ self viewHasCursor
! !

SwitchController subclass: 'LockedSwitchController'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphic Windows'
!

LockedSwitchController comment: 
'I am a SwitchController that will not take control if the model is locked.'
!

! LockedSwitchController methodsFor: 'control' !

isControlWanted
	Sensor flushKeyboard.
	self viewHasCursor ifFalse: [ ^ false ].
	Sensor redButtonPressed ifFalse: [ ^ false ].
	^ model okToChange
! !

View subclass: 'SwitchView'
	instanceVariableNames: 'complemented selector keyCharacter highlightForm arguments '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics Windows'
!

SwitchView comment:
'I am a view of a Switch. My instances have labels and display modes (set to "normal" or "complemented"). When one of my instances is displayed in complemented mode, its inside color is reversed. The value of the display mode corresponds to the value of the model so that, for example, when a Switch is off, its SwitchView is displayed with black text (for the label) on a white background, and when the Switch is on, its SwitchView is displayed with white text on a black background. My instances have a key character that can be used for selecting the model. Highlighting can be done specially using a stored form, rather than simply changing all black bits to white, and vice versa. My instances'' default controller is SwitchController.'
!

! SwitchView methodsFor: 'initialize-release' !

initialize 
	"Refer to the comment in View initialize."
	super initialize.
	complemented <- false.
	label <- nil.
	selector <- #isOn.
	arguments <- Array new: 0
!

release
	super release.
	label release
! !

! SwitchView methodsFor: 'accessing' !

arguments
	"Answer the arguments the receiver sends in a message to its receiver."

	^arguments
!

arguments: anArray
	"The argument, anArray, consists of the arguments of the message
	the receiver sends to its model."

	arguments <- anArray
!

highlightForm: aForm 
	"The argument is the form to be used to highlight the receiver."

	highlightForm <- aForm
!

key: aCharacter 
	"Set the receiver to be selected by the argument, aCharacter."

	keyCharacter <- aCharacter
! !

! SwitchView methodsFor: 'testing' !

containsKey: aCharacter 
	"Answer whether the receiver can be selected by the argument, 
	aCharacter."

	^keyCharacter = aCharacter
! !

! SwitchView methodsFor: 'access' !

defaultControllerClass 
	^SwitchController
! !

! SwitchView methodsFor: 'displaying' !

displayComplemented
	"Complement the receiver if its mode is 'normal'."

	complemented
		ifFalse: 
			[complemented <- true.
			self highlight]
!

displayNormal
	"Complement the receiver if its mode is 'complemented'."

	complemented
		ifTrue: 
			[complemented <- false.
			self highlight]
!

displaySpecial 
	"The receiver has a special highlight form. Use it for displaying 
	complemented, if appropriate."

	complemented
		ifTrue: [ highlightForm displayOn: Display
				at: insetBox origin
				clippingBox: insetBox ].
	label isNil 
		ifFalse: [label  displayOn: Display
		  	        at: insetBox origin
			        clippingBox: insetBox
			        rule: Form under
			        mask: Form black ]
!

display
	"Does the standard View actions and, in addition, displays the receiver's 
	label based on the current display transformation and inset display box."

	displayed <- true.
                Display white: (offset extent: extent).
                Display border: (offset extent: extent)
                             widthRectangle: borderWidth
	             mask: Form black.
	label isNil ifFalse: [ 
			label displayOn: Display
				at: insetBox origin
				clippingBox: insetBox].
	complemented ifTrue: [
		highlightForm isNil ifFalse: [self displaySpecial]
				ifTrue: [ self highlight ]].
! !

! SwitchView methodsFor: 'updating' !

update: aParameter 
	"Refer to the comment in View|update:."
	complemented <- self interrogateModel.
	displayed ifTrue: [ self display ]
! !

! SwitchView methodsFor: 'label access' !

centerLabel
	"Align the center of the frame of the label with the center of the 
	receiver's window."
	displayed ifTrue:  [ self display ]
!

label
	"Answer the label, a display object, that is the receiver's screen image."

	^label
!

label: aDisplayObject 
	"Set aDisplayObject to be the label that is the receiver's screen image."

	label release.
	label <- aDisplayObject.
	self centerLabel
! !

! SwitchView methodsFor: 'indicating' !

indicatorOnDuring: aBlockContext 
	"Indicate the receiver during the execution of aBlockContext by 
	complementing the label (or a portion of the display box if no label is 
	defined)."

	self indicatorReverse.
	self highlight. 
	aBlockContext value.
	self highlight.
	self indicatorReverse
!

indicatorReverse
	"Complement the label (or a portion of the displayBox if no label is 
	defined)."

	Display reverse: insetBox mask: Form gray.
	Display reverse: (insetBox insetBy: 2) mask: Form gray
! !

! SwitchView methodsFor: 'selector' !

interrogateModel
	"Answer the result of sending the receiver's model the message created 
	from the receiver's selector and arguments."
	^ model preform: selector
	"arguments size = 0
		ifTrue: [^model perform: selector]
		ifFalse: [^model perform: selector withArguments: arguments]"
!

selector
	^selector
!

selector: aSymbol 
	selector <- aSymbol
! !

! SwitchView methodsFor: 'deEmphasizing' !

deEmphasize
	complemented ifTrue: [ 
		   Display fill: insetBox 
	    		 rule: Form under
	     		mask: Form veryLightGray ]
!

emphasize
	self display
! !

! SwitchView class methodsFor: 'creating' !

on: aModel aspect: aName label: aString change: changeSelector
	value: getValue 
    | aView |
    aView <- super new.
    aView model: aModel ;
               label: aString ;
               selector: getValue ;
               controller selector: changeSelector. 
     aView name: aName.
    ^ aView
! !

