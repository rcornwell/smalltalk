
" Methods for Class character graphics subclasses"

" $Id: font.st,v 1.1 2002/01/29 16:41:13 rich Exp rich $ "

"
 $Log: font.st,v $
 Revision 1.1  2002/01/29 16:41:13  rich
 Initial revision



"

BitBlt subclass: 'CharacterScanner'
  instanceVariableNames:
    'text textPos xTable stopX exceptions printing font startX'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Character'
!

! CharacterScanner class methodsFor: 'instance creation' !

text: aString destForm: destination font: aFont 
        combinationRule: rule destOrigin: destOrigin
        extent: extent clipRect: clipRect
            "Answer a CharacterScanner with values set according to
            each of the arguments, where rule is an Integer;
            destination, source, and halftone are Forms;
            destOrigin, sourceOrigin, and extent are Points;
            and clipRect is a Rectangle."
    ^self new text: aString destForm: destination font: aFont 
        combinationRule: rule destOrigin: destOrigin
        extent: extent clipRect: clipRect;
	yourself
!

text: aString destForm: destination font: aFont 
    ^self new text: aString destForm: destination font: aFont 
        combinationRule: 3 destOrigin: 0@0
        extent: ((destination width)@(destination height)) clipRect: nil;
	yourself
!

text: aString font: aFont 
    ^self new text: aString destForm: nil font: aFont 
        combinationRule: 3 destOrigin: 0@0
        extent: 0@0 clipRect: nil;
	yourself
! !

! CharacterScanner methodsFor: 'initializing' !

text: aString destForm: destination font: aFont 
        combinationRule: rule destOrigin: destOrigin
        extent: extent clipRect: clipRect
    text <- aString.
    textPos <- 1.
    destForm <- destination.
    exceptions <- Array new: 258.
    exceptions at: 258 put: #endRun.
    exceptions at: 257 put: #crossedX.
    halftoneForm <- nil.
    combinationRule <- rule.
    destX <- destOrigin x.
    destY <- destOrigin y.
    sourceX <- 0.
    sourceY <- 0.
    width <- extent x.
    height <- extent y.
    startX <- 0.
    stopX <- width.
    clipRect isNil ifTrue: [
            clipX <- 0.
            clipY <- 0.
            clipWidth <- destForm width.
            clipHeight <- destForm height.
        ] ifFalse: [
            clipX <- clipRect left.
            clipY <- clipRect top.
            clipWidth <- clipRect width.
            clipHeight <- clipRect height.
    ].
    printing <- true.
    self font: aFont
! !

! CharacterScanner methodsFor: 'accessing'!

text
	^ text
!

textPos
	^ textPos
!

xTable
	^ xTable
!

startX
	^ startX
!

stopX
	^ stopX
!

exceptions
	^ exceptions
!

printing
	^ printing
!

extent
	^ destX @ destY
!

fontHeight
	^ font height
! !

! CharacterScanner methodsFor: 'modifying'!

text: aString
	^ text <- aString
!

textPos: aPosition
	^ textPos <- aPosition
!

xTable: aTable
	^ xTable <- aTable
!

stopX: aPosition
	^ stopX <- aPosition
!

startX: aPosition
	^ startX <- aPosition
!

exceptions: aArray
	^ exceptions <- aArray
!

stopcode: aChar put: aSymbol
	exceptions at: aChar put: aSymbol
!

printing: aBoolean
	^ printing <- aBoolean
!

font: aFont
   | e ne newFont |
    newFont <- aFont font.
    font == newFont ifTrue: [ ^ self ].
    sourceForm <- font raster.
    xTable <- font xTable.
    " Merge execption array's "
    1 to: font stopConditions size do: [ :i | 
	e <- exceptions at: i.
	ne <- font stopConditions at: i.
	(e isNil or: [e == #characterNotInFont] )
		ifTrue: [ exceptions at: i put: ne ].
     ].
!

setRect: aRectangle offset: aInteger
    clipX <- destX <- startX <- aRectangle left.
    stopX <- aRectangle right.
    clipWidth <- width <- aRectangle width.
    clipHeight <- height <- aRectangle height.
    clipY <- aRectangle top.
    destY <- clipY + aInteger.
! !

! CharacterScanner methodsFor: 'character shortcuts'!

endRun
    ^ false
!

crossedX
    ^ self newLine
!

esc
    ^ self nextChar
!

newPage
    ^ self nextChar
!

nextChar
    textPos <- textPos + 1.
    ^ true
!

space
    destX <- destX + font width.
    ^ true
!

carriageReturn
    destX <- startX.
    ^ true
!

newLine
    destX <- startX.
    destY <- destY + font height.
    ^ true
!

backspace
    destX <- destX - font width.
    destX < 0 ifTrue: [ destX <- 0 ].
    ^ true
!

tab
   | col |
   col <- destX // font width.
   destX <- destX + (font width * (8 - col)).
    ^ true
! !

! CharacterScanner methodsFor: 'displaying' !

scanword: endRun
    | charIndex |
    < primitive 135 >
    [ textPos <= endRun ] whileTrue: [
	charIndex <- (text at: textPos) asciiValue + 1.
	(exceptions at: charIndex) notNil
	   ifTrue: [ ^ exceptions at: charIndex ].
	sourceX <- xTable at: charIndex.
	width <- (xTable at: charIndex + 1) - sourceX.
	printing ifTrue: [ self copyBits ].
	destX <- destX + width.
	destX > stopX ifTrue: [ ^ exceptions at: 257 ].
	textPos <- textPos + 1 ].
    textPos <- textPos - 1.
    ^ exceptions at: 258
! !

