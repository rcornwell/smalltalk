View subclass: 'DisplayTextView'
  instanceVariableNames: 'centered rule mask text'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Text'
!

DisplayTextView comment: 
'I am a view of a DisplayText. I do not support editing of my contents'. !


! DisplayTextView methodsFor: 'initialize' !

initialize 
	super initialize.
	centered <- false.
!

setContentsFrom: aString
     self model: (DisplayText text: aString)
! !

! DisplayTextView methodsFor: 'accessing' !

center
     centered <- true.
     self centerText
!

isCentered
     ^ centered
!

mask
    ^ mask
!

rule
    rule == nil ifTrue: [ ^ self defaultRule ]
		ifFalse: [ ^ rule ]
!

rule: aRule
    rule <- aRule
! !

! DisplayTextView methodsFor: 'controller access' !

defaultController
    ^ self defaultControllerClass new: text
!

defaultControllerClass
    ^ DisplayTextEditor
! !

! DisplayTextView methodsFor: 'model access' !

model: aDisplayText
    super model: aDisplayText.
    text <- model asDisplayTextEdit.
! !






     

! DisplayTextView methiodsFor: 'controller' !

defaultControllerClass
    ^NoController
! !

! DisplayTextView methodsFor: 'displaying' !

displayView
    listTop isNil
        ifTrue: [ listTop <- 0 ].
    (BitBlt destForm: Display sourceForm: text form
            halftoneForm: Form black combinationRule: Form over
	    destOrigin: insetBox origin sourceOrigin: 0@listTop
	    extent: insetBox extent clipRect: insetBox)
	copyBits
!

emphasizeView
    ^nil
!

deEmphasizeView
    ^nil
! !


! DisplayTextView methodsFor: 'scrolling' !

fullHeight
    ^ model form height
!

scrollTo: anInteger
    textTop <- anInteger.
    textTop > text form height
        ifTrue: [ textTop <- text form hieght ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    self display
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !

