Form subclass: 'DisplayScreen'
  instanceVariableNames: 'menu controller'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

! DisplayScreen class methodsFor: 'initializing' !

open
    "Initialize the environment."
    | main |
    main <- super new.
    main initDisplay.
    ScheduledControllers <- ControlManager new.
    StandardSystemController initMenus.
    main initialize.
    "main initTranscript."
    main refreshScreen.
    ScheduledControllers scheduleActive: main controller
! !

! DisplayScreen methodsFor: 'setup windows' !

initDisplay
    Display <- self.
    Smalltalk at: #Display put: self.
    self offset: 0@0.
    self beDisplay.
    Cursor normal show.
! !

! DisplayScreen methodsFor: 'setup windows' !

initMenu
    menu <- Menu labelArray: #(
			      'Inspect Active Process'
			      'Workspace'
			      'Class Browser' 
			      'Save Image'	
			      'Prompter Demo'
                              'Refresh Screen'
			      'Exit Smalltalk'
			      'New Backtrace')
		lines: #()
		selectors: #(
			        inspectActiveProcess
				workspace
				fullClassBrowser 
			     	saveImage
				prompterDemo
		             	refreshScreen
				exitSmalltalk
			        newBackTrace)
!

initTranscript
    | trans |
    
    trans <- (StandardSystemView new: (50@100 extent: 300@500))
                                     label: 'System Transcript'; yourself.
    Smalltalk at: #Transcript put: trans.
    " Can't call open here, since we would never return "
    ScheduledControllers schedulePassive: trans controller.
    trans controller
           blueButtonMenu:
	           (Menu labelArray: #('move' 'collapse'
                                       'expand' 'under')
			 lines: #()
			 selectors: #(move collapse
			              expand under)).
! !

! DisplayScreen methodsFor: 'menu items' !

workspace
    ^ StandardSystemView new
            label: 'WorkSpace';
    	  addSubView: (TextView new) in: (0.0@0 extent: 1.0@1.0);
	   open ;
	    yourself.
!

prompterDemo
    | aString |
    aString <- Prompter message: 'Type in a response'
                        default: 'Some default text'.
    stdout nextPutAll: '>>', aString, '<<'. stdout nl
!

newBackTrace
"    Smalltalk backtrace.
    Smalltalk newBacktrace do:
        [ :line | line print. nl print ]"
!

inspectActiveProcess
    Processor activeProcess inspect.
!

saveImage
    System snapshot
!

refreshScreen
    ScheduledControllers restore
!

exitSmalltalk
    System quit
!

fullClassBrowser
    Browser new newBrowser
! !

! DisplayScreen methodsFor: 'running system' !

"When I have controllers, shall I keep this here or have
 a DisplayController (DisplayDisplatcher?)?"

preformMenu
    | menuReturn |
    menuReturn <- menu popUpAt: Sensor mousePoint.
    menuReturn isNil
        ifFalse: [ self preform: menuReturn ]
! !

! DisplayScreen methodsFor: 'compatability with View protocol' !

initialize
" Reload menus on initialize message"
    self initMenu
!

release
    ^self
!

controller
    controller isNil
        ifTrue: [ self controller: self defaultController ].
    ^controller
!

controller: aController
    controller isNil
        ifFalse: [ controller release ].
    controller <- aController.
    controller view: self.
    ^self
!

defaultController
    ^self defaultControllerClass new
!

defaultControllerClass
    ^ScreenController
!

containsPoint: aPoint
    ^self boundingBox containsPoint: aPoint
!

subViewContaining: aPoint
    ^nil
!

subViewWantingControl
    ^nil
!

display
    self lightGray
!

highlight
    ^self reverse
!

flash
    self highlight.
    self highlight
!

emphasize
    ^self
!

deEmphasize
    ^self
! !

