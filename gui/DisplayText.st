DisplayObject subclass: 'DisplayText'
  instanceVariableNames: "width height offset" 'text form'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Text'
!

DisplayText comment:
  'I convert Text with formating information into forms for display.'. !

! DisplayText methodsFor: 'accessing' !

text
    ^text
!

form
    form == nil ifTrue: [ self composeForm ].
    ^form
!

string
    ^ text asString
! !

! DisplayText methodsFor: 'modifying' !

text: aText
    form <- nil.
    text <- aText.
    self changed.
! !

! DisplayText methodsFor: 'displaying' !

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                rule: ruleInteger
                mask: aForm
    self form displayOn: aDisplayMedium
		at: aDisplayPoint + offset
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm
! !

! DisplayText methodsFor: 'private' !

composeForm
! !

