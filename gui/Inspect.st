! MethodContext methodsFor: 'debugging' !

newBacktrace 
    | context aCollection |
    aCollection <- OrderedCollection new.
    context <- self.
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
    context <- self.
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

