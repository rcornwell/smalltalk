TextView subclass: 'PrompterView'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! PrompterView methodsFor: 'accessing' !

nextPut: aCharacter
    (aCharacter == Character nl
        or: [ aCharacter == Character cr ])
	  ifTrue: [ ^controller accept ].
    super nextPut: aCharacter
! !


