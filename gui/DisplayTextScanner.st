
CharacterScanner subclass: 'DisplayTextScanner'
  instanceVariableNames: 
    "text textPos xTable stopX exceptions printing font startX"
	'width height offset'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Text'

!

! DisplayTextScanner methodsFor: 'accessing'!


! DisplayTextScanner methodsFor: 'modifying'!


font: aFont
   | e ne |
    font <- aFont font.
    sourceForm <- font raster.
    xTable <- font xTable.
    " Merge execption array's "
    1 to: font stopConditions size do: [ :i | 
	e <- exceptions at: i.
	ne <- font stopConditions at: i.
	(e isNil or: [e == #characterNotInFont] )
		ifTrue: [ exceptions at: i put: ne ].
     ].


! DisplayTextScanner methodsFor: 'character shortcuts'!

nextChar
    textPos <- textPos + 1.
!

nextline
    destX <- startX.
    destY <- destY + font height.
!

backspace
    destX <- destX - font width.
    destX < 0 ifTrue: [ destX <- 0 ].
!

tab
   | col |
   col <- destX // font width.
   destX <- destX + (font width * (8 - col)).
! !


