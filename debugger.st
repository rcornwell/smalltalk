! MethodContext methodsFor: 'debugging' !

newBacktrace 
    | context aCollection |
    aCollection <- OrderedCollection new.
    context <- self parentContext.
    [ context notNil ]
	 whileTrue: [
		      context backtraceString printOn: stderr. stderr nl.
		      aCollection addLast: context backtraceString.
		      context <- context parentContext ].
    ^aCollection 
! !

! BlockContext methodsFor: 'debugging' !

newBacktrace 
    | context aCollection |
    aCollection <- OrderedCollection new.
    context <- self parentContext.
    [ context notNil ]
	 whileTrue: [  
		      context backtraceString printOn: stderr. stderr nl.
		      aCollection addLast: context backtraceString.
		      context <- context parentContext ].
    ^aCollection 
! !

! StrikeFont methodsFor: 'accessing' !

width
	^ maxWidth
! !

Object subclass: 'Inspector'
  instanceVariableNames: 'theObject instVars instVarLookup currentVariable base'
  classVariableNames: 'VariableMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Inspector methodsFor: 'setup' !

for: anObject
    | instVarNames |
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
!

createViews: topView
    topView addSubView:
	 (ListView on: self 
		   aspect: #variableList
		   change: #variable:
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
! !

! Inspector class methodsFor: 'initialising' !

openOn: anObject
    |  inspector topView |
    inspector <- super new.
    inspector for: anObject.
    topView <- StandardSystemView new
                  label: 'Inspector for ', (anObject class printString);
		  yourself.
    inspector createViews: topView.
    topView open.
    ^ inspector
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
        ifTrue: [ Inspector openOn: theObject ].
    currentVariable > base
        ifTrue: [ Inspector openOn: (theObject basicAt: currentVariable - base) ]
        ifFalse: [ Inspector openOn: (theObject instVarAt: currentVariable - 1) ].
! !

! Object methodsFor: 'debugging' !

inspect
    Inspector openOn: self.
! !

! MethodContext methodsFor: 'accessing' !

home
	^ self
!

argcount
	^ argcount
! !

Object subclass: 'Debugger'
	instanceVariableNames: 'process stack stackView stackIndex context currentContext methodText currentMethod receiver recInstVars recInstVarLookup recCurrentVariable recBase stackVar stackVars stackLookup'
	classVariableNames: ' VariableMenu StackVariableMenu'
	poolDictionaries: ''
	category: 'Graphics Windows'
!

! Debugger class methodsFor: 'instance creation' !

message: aString notifying: aNotifier stack: aStack on: aContext process: aProcess
  ^self new message: aString notifying: aNotifier stack: aStack on: aContext process: aProcess; yourself
! !

! Debugger methodsFor: 'initialising' !

message: aString notifying: aNotifier stack: aStack on: aContext process: aProcess
    | topView |
    context <- aContext.
    process <- aProcess.
    stack <- aStack.
    stackIndex <- nil.
    currentContext <- nil.
    currentMethod <- ''.
    receiver <- nil.
    recInstVars <- OrderedCollection new.
    recInstVarLookup <- Dictionary new.
    recCurrentVariable <- nil.
    stackVar <- nil.
    stackVars <- OrderedCollection new.
    stackLookup <- Dictionary new.
    topView <- StandardSystemView model: self label: aString.
    topView addSubView:
	   (stackView <- ListView on: self 
		   aspect: #stackTrace
		   change: #setStack:
		   menu: #stackMenu
		   initialSelection: nil)
	   in: (0@0 extent: 1.0@0.25).
    topView addSubView:
         (methodText <- TextView on: self
		   aspect: #methodText
		   change: #methodText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0.0@0.25 extent: 1.0@0.5).
   topView addSubView:
	   (ListView on: self 
		   aspect: #selfVars
		   change: #setSelfVar:
		   menu: #selfMenu
		   initialSelection: nil)
	   in: (0@0.75 extent: 0.25@0.25).
    topView addSubView:
         (TextView on: self
		   aspect: #selfVarText
		   change: #selfVarText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0.25@0.75 extent: 0.25@0.25).
    topView addSubView:
	   (ListView on: self 
		   aspect: #stackFrameNames
		   change: #setStackFrame:
		   menu: #stackFrameMenu
		   initialSelection: nil)
	   in: (0.5@0.75 extent: 0.25@0.25).
    topView addSubView:
         (TextView on: self
		   aspect: #stackVarText
		   change: #stackVarText: 
		   menu: nil
		   initialSelection: nil)
	    in: (0.75@0.75 extent: 0.25@0.25).
    topView setSize: Rectangle fromUser.
    topView controller startUp
! !

! Debugger methodsFor: 'accesing' !

setStack: aSelect
	| index meth instVarNames comp locations range |

	stderr nextPutAll: 'setStack: '.
	aSelect printOn: stderr. stderr nl.
	currentContext <- nil.
	currentMethod <- ''.
	receiver <- nil.
   	recInstVars <- OrderedCollection new.
    	recInstVarLookup <- Dictionary new.
    	recCurrentVariable <- nil.
   	stackVar <- nil.
    	stackVars <- OrderedCollection new.
    	stackLookup <- Dictionary new.
	stackIndex <- stackView currentSelection.
	stackIndex isNil ifFalse: [
		stderr nextPutAll: 'Finding context'. stderr nl.
	     currentContext <- context.
	     index <- stackIndex - 1.
	    " Walk up stack to find method "
	     [ index > 0 ] whileTrue: [ 
		currentContext <- currentContext  parentContext.
		index <- index - 1 ].
		stderr nextPutAll: 'Found context'. stderr nl.
	  " Get the source for the method "
	     meth <- currentContext home.
	     receiver <- meth receiver.
	
 	   " Build list for receiver of method "
		stderr nextPutAll: 'Building reciever stack'. stderr nl.
    	     recInstVars add: 'receiver'.
   	     recInstVarLookup at: #receiver put: 1.
    	     instVarNames <- receiver class allInstVarNames.
    	     1 to: instVarNames size do:
       	     [ :x | recInstVars add: (instVarNames at: x) asString.
	       	recInstVarLookup at: (instVarNames at: x) asString
	                     put: x + 1 ].
   	      recBase <- recInstVars size.
  	       receiver class isVariable
        		ifTrue: [ 1 to: (receiver basicSize min: 100) do:
	           		[ :x | recInstVars add: x printString.
		         		 recInstVarLookup at: x printString
			               		 put: recBase + x ] ].
	    " Now we need to recompile the source for the method so we can
	       find out where we are and all the temporaries"
		stderr nextPutAll: 'recompiling source'. stderr nl.
     	     meth <- meth method.
	     meth isNil ifFalse: [
	          currentMethod <- meth getSource.
		  stderr nextPutAll: currentMethod.
	          methodText setContentsFrom: currentMethod.
	          comp <- SmallTalkParser on: currentMethod
				forClass: receiver class
				msgpattern: true
				notify: nil.
		stderr nextPutAll: 'Finding stop point'. stderr nl.
	          locations <- comp codePosition.
	          index <- currentContext ip.
	          range <- nil.
	          " Walk the list of instructions and choose the closest one "
	          locations associationsDo:  [ :assoc |
		    assoc key < index ifTrue: [
			range isNil ifTrue: [ range <- assoc ]
				   ifFalse: [ assoc key > range key 
						ifTrue: [ range <- assoc ]]]].
	          range isNil ifFalse: [ methodText setInsertPoint: range value end ].
	          index <- 0.
		stderr nextPutAll: 'Loading arguments'. stderr nl.
	          comp arguments printOn: stderr. stderr nl.
	          comp arguments do: [ :arg |
			index <- index - 1.
			stackVars add: arg asString.
			stackLookup at: arg asString put: index
	          ].
	          index <- 1.
		stderr nextPutAll: 'Loading temps'. stderr nl.
     	          comp tempvars printOn: stderr. stderr nl.
	          comp tempvars do: [ :temp |
			stackVars add: temp asString.
			stackLookup at: temp asString put: index.
			index <- index + 1
	          ]
	      ] ifTrue: [
		stderr nextPutAll: 'Clearing'. stderr nl.
	          methodText setContentsFrom: (currentMethod <- '"Unable to find method"' ).
	      ]
	] ifTrue: [
	    methodText setContentsFrom: (currentMethod <- '"Unable to find method"' ).
	].
	methodText display.
	self changed: #selfVars.
	self changed: #selfVarText.
	self changed: #stackFrameNames.
	self changed: #stackVarText
	
!

stackTrace
	^ stack
!

stackMenu
	^ nil
!

methodText
	^ currentMethod
!

methodText: aSelect
!

selfVars
    ^recInstVars
!

setSelfVar: aString
    | index |
    aString isNil
        ifTrue: [ recCurrentVariable <- nil ]
        ifFalse: [ index <- recInstVarLookup at: aString ifAbsent: [ 1 ].
                   recCurrentVariable == index
                       ifTrue: [ ^self ].
                   recCurrentVariable <- index ].
    self changed: #selfVarText
!

selfMenu
    recCurrentVariable isNil ifTrue: [ ^ nil ].
    VariableMenu isNil ifTrue: [
	    VariableMenu <- Menu labelArray: #('inspect')
	                          lines: #()
				  selectors: #(recInspect)].
   ^ VariableMenu
!

selfVarText
    recCurrentVariable isNil
        ifTrue: [ ^String new: 0 ].
    recCurrentVariable == 1
        ifTrue: [ ^receiver printString ].
    recCurrentVariable > recBase
        ifTrue: [ ^(receiver basicAt: recCurrentVariable - recBase)
	                printString ].
    ^(receiver instVarAt: recCurrentVariable - 1) printString
!

recInspect
    recCurrentVariable isNil
        ifTrue: [ ^nil ].
    recCurrentVariable == 1
        ifTrue: [ Inspector openOn: receiver ].
    recCurrentVariable > recBase
        ifTrue: [ Inspector openOn: (receiver basicAt: recCurrentVariable - recBase) ]
        ifFalse: [ Inspector openOn: (receiver instVarAt: recCurrentVariable - 1) ].
!

stackFrameNames
	^ stackVars
!

setStackFrame: aString
    | index |
    aString isNil
        ifTrue: [ stackVar <- nil ]
        ifFalse: [ index <- stackLookup at: aString ifAbsent: [ 1 ].
                   stackVar == index
                       ifTrue: [ ^self ].
                   stackVar <- index ].
    self changed: #stackVarText
!

stackFrameMenu
    stackVar isNil ifTrue: [ ^ nil ].
    StackVariableMenu isNil ifTrue: [
	    StackVariableMenu <- Menu labelArray: #('inspect')
	                          lines: #()
				  selectors: #(stackInspect)].
   ^ StackVariableMenu
!

stackVarText
    | cntxt index |
    stackVar isNil
        ifTrue: [ ^String new: 0 ].
    stackVar >= 0
        ifTrue: [ cntxt <- currentContext home.
	       index <- stackVar   ]
        ifFalse: [ cntxt <- currentContext sender home.
                        index <- (cntxt sp - cntxt class instSize) + (currentContext argcount + stackVar) + 1.
	        index printOn: stderr. stderr nl.
        ]. 
	       
   ^ ( cntxt basicAt: index ) printString
!

stackVarText: aSelect
!

stackInspect
    | cntxt index |
    stackVar isNil
        ifTrue: [ ^nil ].
    stackVar >= 0
        ifTrue: [ cntxt<- currentContext home.
	       index <- stackVar   ]
        ifFalse: [ cntxt<- currentContext sender home.
                        index <- (cntxt sp - cntxt class instSize) + (currentContext argcount + stackVar) + 1.
	        index printOn: stderr. stderr nl.
        ]. 
    Inspector openOn: (cntxt basicAt: index )
! !

Object subclass: 'Notifier'
instanceVariableNames: 'status theMessage backtraceList proceedValue'
classVariableNames: ''
poolDictionaries: ''
category: 'Graphics Windows'
!

! Notifier methodsFor: 'accessing' !

proceedValue
	^ proceedValue
! !

! Notifier methodsFor: 'modifying' !

proceedValue: anObject
	^ proceedValue <- anObject
! !

! Notifier methodsFor: 'initialising' !

message: aString
    | aStream contentsList topView subView errorContext |
	stderr nextPutAll: 'Notifier: '.
	stderr nextPutAll: aString.
	stderr nl.
    theMessage <- aString.
    proceedValue <- nil.
    errorContext <- thisContext parentContext parentContext parentContext.
    contentsList <- errorContext newBacktrace.
    aStream <- WriteStream on: (String new: 0).
    1 to: (contentsList size max: 10) do:
        [ :line | aStream nextPutAll: (contentsList at: line). aStream nl ].
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
    status == #debug ifTrue: [ Debugger	message: theMessage 
				notifying: self 
				stack: contentsList
				on: errorContext
				process:  Processor activeProcess ].
    ScheduledControllers restore.
    ^ proceedValue
! !

! Object methodsFor: 'Error Handling' !

error: aString
    ^ self notify: (self printString, ' error: ', aString)
! !

! Object methodsFor: 'notifiers' !

notify: aString
    ^Notifier message: aString
! !



