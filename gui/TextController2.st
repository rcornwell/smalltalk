ScrollController subclass: 'TextController'
  instanceVariableNames: ''
  classVariableNames: 'BlueMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextController methodsFor: 'initialize' !

initialize
     super initialize.
     BlueMenu isNil ifTrue: [
          BlueMenu <- Menu labelArray: #( 'again' 'undo' 'copy'
				 'cut' 'paste' 'do it' 'print it' 'accept'
				 'cancel')
                                 lines: #( 2 5 7)
				 selectors: #(again undo copySelect cut paste
				   doit printit accept cancel).
     ].
     self blueButtonMenu: BlueMenu notifying: self.
! !

! TextController methodsFor: 'control' !

controlActivity
    Sensor keyboardPressed
        ifTrue: [ ^view keypress: Sensor keyboard ].
    super controlActivity
!

redButtonActivity
    | position oldPosition |
    oldPosition <- Sensor mousePoint.
    view setInsertPointFrom: oldPosition.
    [ Sensor waitMouse. Sensor redButtonPressed ]
           whileTrue: [  position <- Sensor mousePoint.
	                position = oldPosition
		            ifFalse: [ oldPosition <- position.
			               view setSelectionFrom: position ] ].
! !

! TextController methodsFor: 'editing' !

again
   view again
!

undo
   view undo
!

copySelect
   view copySelect
!

cut
   view cut
!

paste
   view paste
!

doit
   view doit
!

printit
   view printit
!

cancel
    view cancel
!

accept
    ^self changed
!

contents
    stdout nextPutAll: view contents. stdout nl
! !

