" Basic GUI applications for Smalltalk. "

" Copyright 1999-2017 Richard P. Cornwell.
 
  This program is free software; you can redistribute it and/or modify it
  under the terms of the the Artistic License (2.0). You may obtain a copy
  of the full license at:
 
  http://www.perlfoundation.org/artistic_license_2_0
 
  Any use, modification, and distribution of the Standard or Modified
  Versions is governed by this Artistic License. By using, modifying or
  distributing the Package, you accept this license. Do not use, modify, or
  distribute the Package, if you do not accept this license.
 
  If your Modified Version has been derived from a Modified Version made by
  someone other than you, you are nevertheless required to ensure that your
  Modified Version complies with the requirements of this license.
 
  This license does not grant you the right to use any trademark, service
  mark, tradename, or logo of the Copyright Holder.
 
  Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
  AND CONTRIBUTORS 'AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
  THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
  YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
  CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
  CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. "


" $Id: guiapps.st,v 1.2 2002/02/17 13:41:59 rich Exp rich $ "

"
 $Log: guiapps.st,v $
 Revision 1.2  2002/02/17 13:41:59  rich
 Added new methods to Browser class.
 Made DisplayScreen initSystem method work.
 Fixed Notifier.
 Added Workspace window.

 Revision 1.1  2002/01/29 16:41:50  rich
 Initial revision


"

StandardSystemController subclass: 'NotifyController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
category: 'Graphics Windows'
!

! NotifyController methodsFor: 'control' !

isControlWanted
  ^true
!

isControlActive
  ^status ~= #inactive
!

controlActivity
  self viewHasCursor
      ifTrue: [ super controlActivity ]
! !

! NotifyController methodsFor: 'blue button menu items' !

proceed
  model proceed.
  view release.
  self release.
  status <- #inactive
!

debug
  model debug.
  view release.
  self release.
  status <- #inactive
!

traceDump
  model isNil
      ifTrue: [ ^nil ].
  model traceDump
! !

Object subclass: 'Notifier'
instanceVariableNames: 'status theMessage backtraceList'
classVariableNames: ''
poolDictionaries: ''
category: 'Graphics Windows'
!

! Notifier class methodsFor: 'instance creation' !

message: aString
  ^self new message: aString; yourself
! !

! Notifier methodsFor: 'initialising' !

message: aString
    | aStream contentsList topView subView |
	stderr nextPutAll: 'Notifier: '.
	stderr nextPutAll: aString.
	stderr nl.
    theMessage <- aString.
    contentsList <- System newBacktrace.
    aStream <- WriteStream on: (String new: 0).
    contentsList do:
        [ :line | aStream nextPutAll: line. aStream nl ].
    backtraceList <- aStream contents.
	stderr nextPutAll: backtraceList. stderr nl.
	stderr nextPutAll: 'makeing views '.
    topView <- StandardSystemView new: (100@100 extent: 300@200);
                                  label: theMessage;
				  model: self ;
				  yourself.
	stderr nextPutAll: 'text '.
    subView <- TextView on: self aspect: #backTrace change: nil
				menu: nil initialSelection: nil.
    topView addSubView: subView in: (0@0 extent: 1.0@1.0).
    topView setSize: (100@100 extent: 300@200).
    topView controller: NotifyController new.
    subView controller blueButtonMenu:
                              (Menu labelArray: #('proceed' 'debug'
			                          'trace dump')
                                    lines: #(2)
		                    selectors: #(proceed debug
				                 traceDump))
		       notifying: topView controller.
	stderr nextPutAll: 'startup'. stderr nl.
    topView controller startUp.
    stderr nextPutAll: 'notifier terminated: ' , theMessage. stderr nl.
    stderr nextPutAll: 'status now is to: '.
    status printOn: stderr. stderr nl.
    ScheduledControllers restore
!

backTrace
    ^backtraceList
! !

! Notifier methodsFor: 'actions' !

proceed
    status <- #proceed
!

debug
    status <- #debug
!

traceDump
    | aFile |
    aFile <- FileStream open: 'TraceDump' mode: 'a'.
    aFile nextPutAll: theMessage. aFile nl.
    aFile nextPutAll: backtraceList. aFile nl.
    aFile close
! !

Object subclass: 'Prompter'
  instanceVariableNames: 'defaultResponse promptView'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Prompter class methodsFor: 'instance creation' !

message: aString
    ^self new message: aString default: ' '
!

message: aString default: aResponse
    ^self new message: aString default: aResponse
! !

! Prompter methodsFor: 'initialise-release' !

message: aString default: aResponse
    | topView width height position |
    defaultResponse <- aResponse.
    width <- (aResponse size max: 40) * 10.
    height <- 25.
    position <- Sensor mousePoint - (width // 2 @ height).
    topView <- (StandardSystemView new: (position extent: width @ height))
                   label: aString;
		   model: self;
		   yourself.
    promptView <- (PrompterView new: (position extent: width @ height))
                                model: self;
				name: #prompter;
				change: #accept:from:.
    topView addSubView: promptView.
    topView controller: PrompterController new.
    promptView controller yellowButtonMenu:
                              (Menu labelArray: #('accept')
                                    lines: #()
		                    selectors: #(accept))
		       notifying: topView controller.
    topView controller startUp.
    ScheduledControllers restore.
    ^defaultResponse
! !

! Prompter methodsFor: 'accessing' !

accept
    ^promptView changed
!

prompter
    ^defaultResponse
!

accept: aString from: aController
    (aString includes: Character nl)
        ifTrue:
	  [ defaultResponse <- aString copyFrom: 1
	                               to: (aString indexOf:
				               Character nl) - 1 ]
        ifFalse: [ defaultResponse <- aString ]
! !

Object subclass: 'Browser'
  instanceVariableNames: 'catList classList theClass theMethod methodType'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Browser methodsFor: 'initialising' !

newBrowser
    | topView |
    catList <- Browser allCategories.
    classList <- nil.
    theClass <- nil.
    theMethod <- nil.
    methodType <- #instance.
    topView <- StandardSystemView new
                   label: 'Class Hierarchy Browser'; yourself.
    topView addSubView:
	   (ListView on: self 
		   aspect: #category
		   change: #category:
		   list: #catList
		   menu: #catMenu
		   initialSelection: nil)
	   in: (0@0 extent: 0.25@0.5).
    topView addSubView:
	   (ListView on: self 
		   aspect: #classes
		   change: #classSelection:
		   list: #classList
		   menu: #classMenu
		   initialSelection: nil)
	   in: (0.25@0 extent: 0.25@0.4).
    topView addSubView:
           (ListView on: self
		aspect: #instance
		change: #instance:
		list: #( 'instance' )
		menu: nil
		initialSelection: 'instance' ;
		setSelection: 1;
		yourself)
	    in: (0.25@0.4 extent: 0.125@0.1).
    topView addSubView:
           (ListView on: self
		aspect: #class
		change: #class:
		list: #( 'class' )
		menu: nil
		initialSelection: nil)
	    in: (0.25@0.4 extent: 0.125@0.1).
    topView addSubView:
           (ListView on: self
		aspect: #classCat
		change: #classCat:
		list: #classCatList
		menu: #classCatMenu
		initialSelection: nil)
	    in: (0.5@0 extent: 0.25@0.5).
    topView addSubView:
           (ListView on: self
		aspect: #methods
		change: #method:
		list: #methodList
		menu: #methodMenu
		initialSelection: nil)
	    in: (0.75@0.0 extent: 0.25@0.5).
    topView addSubView:
         (TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0@ 0.5 extent: 1.0@0.5).
    topView open.
! !

! Browser methodsFor: 'accessing' !


catList
	^ catList
!

catMenu
    ^ nil
!

category: aString
    | aStream classString |
    aString isNil
        ifTrue: [ classList <- Array new: 0 ]
	ifFalse: [ classList <- OrderedCollection new: 0.
		   (Object allClassesForCategory: aString)
			do: [ :class | classList add: class printString ]].
    theClass <- nil.
    theMethod <- nil.
    self changed: #class;
         changed: #methods;
         changed: #text
!


catList
	^ catList
!

catMenu
    ^ nil
!

category: aString
    | aStream classString |
    aString isNil
        ifTrue: [ classList <- Array new: 0 ]
	ifFalse: [ classList <- OrderedCollection new: 0.
		   (Object allClassesForCategory: aString)
			do: [ :class | classList add: class printString ]].
    theClass <- nil.
    theMethod <- nil.
    self changed: #class;
         changed: #methods;
         changed: #text
!

classList
    ^classList
!

classSelection: aString
    | aStream classString |
    aString isNil
        ifTrue: [ classString <- 'UndefinedObject' ]
	ifFalse: [ aStream <- WriteStream on: (String new: 0).
	           aString do:
		         [ :char | char ~= Character space
		                      ifTrue: [ aStream nextPut: char ] ].
		   classString <- aStream contents ].
    theClass <- Smalltalk at: classString asSymbol
                          ifAbsent: [ nil ].
    theMethod <- nil.
    self changed: #methods;
         changed: #text
!

methods
    theClass isNil
        ifTrue: [ ^Array new: 0 ].
    methodType == #class
        ifTrue: [ ^theClass class selectors ]
	ifFalse: [ ^theClass selectors ]
!

method: aString
    aString isNil
        ifTrue: [ theMethod <- nil ]
	ifFalse: [ theMethod <- aString asSymbol ].
    self changed: #text
!

instance
    ^#( 'instance' )
!

instance: aString
    theMethod <- nil.
    methodType <- #instance.
    self changed: #class;
         changed: #methods;
	 changed: #text
!

class
    ^#( 'class' )
!

class: aString
    theMethod <- nil.
    methodType <- #class.
    self changed: #instance;
         changed: #methods;
	 changed: #text
!

text
    (theClass isNil or: [ theMethod isNil ])
        ifTrue: [ ^String new: 0 ].
    methodType == #class
        ifTrue: [ ^theClass class sourceCodeAt: theMethod ]
	ifFalse: [ ^theClass sourceCodeAt: theMethod ]
!

accept: aString from: aController
    (theClass isNil or: [ theMethod isNil ])
        ifTrue: [ ^nil ].
    theClass compile: aString notifying: self
! !

Object subclass: 'Inspector'
  instanceVariableNames: 'theObject instVars instVarLookup currentVariable base topController'
  classVariableNames: 'VariableMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Inspector methodsFor: 'initialising' !

openOn: anObject
    | instVarNames topView |
    theObject <- anObject.
    instVars <- OrderedCollection new.
    instVarLookup <- Dictionary new.
    currentVariable <- nil.
    instVars add: 'self'.
    instVarLookup at: #self put: 1.
    instVarNames <- theObject class allInstVarNames.
    1 to: instVarNames size do:
        [ :x | instVars add: (instVarNames at: x) asString.
	       instVarLookup at: (instVarNames at: x) asString
	                     put: x + 1 ].
    base <- instVars size.
    theObject class isVariable
        ifTrue: [ 1 to: (theObject basicSize min: 100) do:
	           [ :x | instVars add: x printString.
		          instVarLookup at: x printString
			                put: base + x ] ].
    topView <- StandardSystemView new
                  label: 'Inspector for ', (theObject class printString);
		  yourself.
    topView addSubView:
	 (ListView on: self 
		   aspect: #variable
		   change: #variable:
		   list: #variableList
		   menu: #variableMenu
		   initialSelection: nil)
	   in: (0@0 extent: 0.25@1.0).
    topView addSubView:
         (TextView on: self
		   aspect: #text
		   change: #text: 
		   menu: nil
		   initialSelection: nil)
	  in: (0.25@0 extent: 0.75@1.0).
    topView open.
! !

! Inspector methodsFor: 'accessing' !

variableList
    ^instVars
!

variable: aString
    | index |
    aString isNil
        ifTrue: [ currentVariable <- nil ]
        ifFalse: [ index <- instVarLookup at: aString ifAbsent: [ 1 ].
                   currentVariable == index
                       ifTrue: [ ^self ].
                   currentVariable <- index ].
    self changed: #text
!

variableMenu
    currentVariable isNil ifTrue: [ ^ nil ].
    VariableMenu isNil ifTrue: [
	    VariableMenu <- Menu labelArray: #('inspect')
	                          lines: #()
				  selectors: #(inspect)].
   ^ VariableMenu
!

text
    currentVariable isNil
        ifTrue: [ ^String new: 0 ].
    currentVariable == 1
        ifTrue: [ ^theObject printString ].
    currentVariable > base
        ifTrue: [ ^(theObject basicAt: currentVariable - base)
	                printString ].
    ^(theObject instVarAt: currentVariable - 1) printString
!

inspect
    currentVariable isNil
        ifTrue: [ ^nil ].
    currentVariable == 1
        ifTrue: [ Inspector new openOn: theObject ].
    currentVariable > base
        ifTrue: [ Inspector new
	              openOn: (theObject basicAt: currentVariable - base) ].
    Inspector new openOn: (theObject instVarAt: currentVariable - 1)
! !

! Object methodsFor: 'debugging' !

inspect
    Inspector new openOn: self.
! !

! Behavior methodsFor: 'hierarchy listing' !

fullListHierarchy
    "answer an ordered collection of the class hierarchy headed
     by the receiver, but don't include metaclasses
     which is a strange thing"
    | aCollection mySubclasses |
    aCollection <- OrderedCollection new.
    (self isKindOf: MetaClass) ifTrue: [ ^aCollection ].
    aCollection add: self name printString.
    mySubclasses <- self subclasses.
    mySubclasses isNil
        ifTrue: [ ^aCollection ].
    (mySubclasses asSortedCollection:
                       [ :a :b | (a name isNil or: [ b name isNil ])
		                      ifTrue: [ true ]
				      ifFalse: [ a name <= b name ] ])
	do: [ :class | class fullListHierarchy do:
	               [ :subclass | aCollection add:
		                          '    ' , subclass ] ].
    ^aCollection
! !

Form subclass: 'DisplayScreen'
  instanceVariableNames: 'menu controller'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

! DisplayScreen class methodsFor: 'initializing' !

initSystem
    "Initialize the environment."
    | main |
    main <- super new.
    main initDisplay.
    ScheduledControllers <- ControlManager new.
    StandardSystemController initMenus.
    main initMenu.
    "main initTranscript."
    main refreshScreen.
    ScheduledControllers scheduleActive: Display controller
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
!

run
    | menuReturn |
	'Run loop' printOn: stderr. stderr nl.
    [ Sensor waitEvent ]
        whileTrue:
	[ 'Event ' printOn: stderr. stderr nl.
	  Sensor keyboardPressed
	      ifTrue: [ Sensor keyboard printNl ].
	  Sensor blueButtonPressed
	      ifTrue: [ menuReturn <- menu popUpAt: Sensor mousePoint.
	                menuReturn isNil
			    ifFalse: [ self preform: menuReturn ] ] ]
! !

! DisplayScreen methodsFor: 'compatability with View protocol' !

initialize
    self initSystem
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

