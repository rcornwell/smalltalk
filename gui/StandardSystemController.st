MouseMenuController subclass: 'StandardSystemController'
  instanceVariableNames: 'status'
  classVariableNames: 'OpenMenu CollapsedMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! StandardSystemController class methodsFor: 'initialising' !

initialize
    OpenMenu <- Menu labelArray: #('move' 'close' 'collapse'
                                   'resize' 'under')
	             lines: #()
		     selectors: #(move close collapse
		                  resize under).
    CollapsedMenu <- Menu labelArray: #('move' 'close' 'open'
                                        'resize' 'under')
			  lines: #()
			  selectors: #(move close open
			               resize under)
! !

! StandardSystemController methodsFor: 'initialize-release' !

initialize
    super initialize.
    status <- #inactive.
    self initializeBlueButtonMenu.
!

initializeBlueButtonMenu
    self blueButtonMenu: OpenMenu
! !

! StandardSystemController methodsFor: 'control' !

isControlActive
    status == #active ifFalse: [ ^ false ].
    Sensor anyButtonPressed ifFalse: [ ^ true ].
    ^ self viewHasCursor 
!

controlInitialize
    view display.
    view emphasize
!

controlTerminate
    view isNil
        ifFalse: [ view deEmphasize ]
! !

! StandardSystemController methodsFor: 'blue button menu items' !

move
   " Ask user for new origin for window "
   view move.
!

close
    " Stops window "
    view close. "Give view a chance to clean things up first "
    view release.
    self release.
    status <- #inactive.
    ScheduledControllers unschedule: self
!

collapse
    " Colapse window to just it's label. "
    status <- #collapsed.
    " Ask user for place to put it "
    self blueButtonMenu: CollapsedMenu.
    ScheduledControllers restore.
    ScheduledControllers searchForActiveController
!

resize
    "Ask user for new frame for this window "
    view resize.
!

under
    " Move window to bottom of stack "
    ScheduledControllers under
!

open
    " Open the window, if not size or origin given ask user for one."
    status <- #active.
    self blueButtonMenu: OpenMenu.
    ScheduledControllers restore.
    ScheduledControllers searchForActiveController
! !

StandardSystemController initialize !


isControlWanted
    " Same as Controller"
    ^self viewHasCursor
!

controlInitialize
    " Same as Controller"
    ^self
!

controlLoop
    " Same as Controller"
    [ self isControlActive ]
        whileTrue: [ 
	Processor yield. 
	Sensor waitEvent. 
	self controlActivity ]
!

controlTerminate
    " Same as Controller"
    ^self
!

controlActivity
    " Same as Controller"
    self controlToNextLevel
!

controlToNextLevel
    " Same as Controller"
    | aView |
    view isNil
        ifTrue: [ ^nil ].
    aView <- view subViewWantingControl.
    aView ~~ nil ifTrue: [ aView controller startUp ]
! !

! StandardSystemController methodsFor: 'cursors' !

centerCursorInView
    " Same as Controller"
    ^nil
!

viewHasCursor
    " Same as Controller"
    view isNil
        ifTrue: [ ^false ].
    ^view containsPoint: Sensor mousePoint
! !

