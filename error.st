
! Object methodsFor: 'errors' !

"These are normally primitives which try to do a callback to the
 originally running context using longjump(), however in this system
 that context will not exist."

"doesNotUnderstand: message
    | aString |
    aString <- self printString, ' does not understand selector '''.
    (message isKindOf: Message)
        ifTrue: [ aString <- aString, message selector printString ]
	ifFalse: [ aString <- aString, message printString ].
    aString <- aString, ''''.
    self notify: aString"
!

"error: aString
    self notify: self printString, ' error: ', aString"
! !

! Object methodsFor: 'notifiers' !

notify: aString
    ^Notifier message: aString
! !

