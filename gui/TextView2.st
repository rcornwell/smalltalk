View subclass: 'TextView'
  instanceVariableNames: 'buffer lineStart lineEnd lineHeight textHeight textWidth textTop insertPoint currentLine charScanner selectStart selectPoint beforeSize gapSize afterSize original cutbuffer againcmd'
  classVariableNames: 'InsertPoint'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextView class methodsFor: 'initialize' !

initialize
    InsertPoint <- Form extent: 8@4
                      fromArray: #(
				2r00011000
				2r00111100
				2r01100110
				2r11000011)
		      offset: -4@0
! !

! TextView class methodsFor: 'displaying' !

on: aModel aspect: aName change: changeSelector
	menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
	  name: aName ;
          changed: changeSelector.
    aMenu isNil ifFalse: [ 
          aView controller blueButtonMenu: aMenu notifying: aView controller ].
    ^ aView
! !

! TextView methodsFor: 'initialising' !

initialize
    | code |
    " Initialize line arrays "
    super initialize.
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- ''.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- 0.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.
    lineStart add: 1.
    lineHeight add: 0.
    textHeight <- charScanner fontHeight.
!

setContentsFrom: aString
    | code |
    " Initialize line arrays "
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- aString.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    " Copy aString to work buffer "
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- aString size.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    charScanner textPos: gapSize.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.

    [ code <- charScanner scanword: buffer size.
      code == #endRun ] whileFalse: [
	textWidth <- textWidth max: charScanner destX.
	code == #stopX ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: charScanner textPos.
		charScanner nextline ].
        code == #nl ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: (charScanner textPos + 1).
		charScanner nextline ].
	code == #bs ifTrue: [ charScanner backspace ].
	code == #tab ifTrue: [ charScanner tab ].
	charScanner nextChar.
    ].
    lineHeight add: charScanner destY.
    charScanner nextline.
    lineStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
! !

! TextView methodsFor: 'accessing' !

defaultControllerClass
    ^ TextController
!

fullHeight
    textHeight == 0
        ifTrue: [ ^ self height ]
        ifFalse: [ ^ textHeight ]
! !

! TextView methodsFor: 'displaying' !

display
    displayed <- true.
    extent isNil
        ifTrue: [ self error: 'TextView has no extent!!' ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    textTop isNil
        ifTrue: [ textTop <- 0 ].
    self showText.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

showText
    | start end second last line lineLen temp textBottom moreText |
    " Set up scanner. "

    lineStart size = 1 ifTrue: [ ^ self ].
    " Compute where we need to display "
    start <- 1.
    end <- lineHeight size.
    textBottom <- textTop + insetBox height.
    1 to: lineHeight size do: [ :t |
	 temp <- lineHeight at: t.
	 temp < textTop ifTrue: [ start <- t ].
	 temp <= textBottom ifTrue: [ end <- t ].
    ].
    " Do dirty work of displaying text "
    line <- start.
    start <- lineStart at: start.
    end <- lineStart at: (end + 1).
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    temp <- textTop - (lineHeight at: line).
    charScanner setRect: insetBox offset: temp negated.

    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].

    charScanner textPos: start.

    " Check if at insert point "
    start == lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- lineStart at: (line + 1).
    ]. 
    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          (temp == #endRun or: [ temp == #stopX ] ) ] whileFalse: [
	   " temp == #nl ifTrue: [ charScanner nextline ]."
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	
  
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
	] ifFalse: [
            charScanner textPos >= end 
	ifTrue: [ moreText <- false ]
	ifFalse: [
		temp == #endRun ifTrue: [ charScanner nextline. ].
		 line <- line + 1.
                               lineLen <- lineStart at: (line + 1).
		(second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
	].
            ].
    ].

    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

clearSelection
	selectStart isNil ifFalse: [ self reverseSelection ].
	selectStart <- nil.
	selectPoint <- nil.
!

reverseSelection
	| temp start |

        " Display highlighted section "
	insertPoint isNil ifTrue: [
		selectStart <- nil.
		selectPoint <- nil.
		^ self ].	
        selectStart isNil ifTrue: [ ^self ].
	selectStart == beforeSize ifTrue: [ ^ self ].
	selectPoint <- self indexToPoint: selectStart + 1.

    " Set up scanner to correct start point.  "
   	charScanner printing: false.
	charScanner setRect: insetBox offset: 0.
	charScanner destOrigin: selectPoint. 
	charScanner textPos: selectStart + 1.
	start <- charScanner destPoint.
    	[ temp <- charScanner scanword: beforeSize.
     	     temp == #endRun ] whileFalse: [
	    (temp == #nl or: [ temp == #stopX ] ) ifTrue: [
   		 (BitBlt destForm: Display sourceForm: nil 
			 halftoneForm: Form black combinationRule: Form reverse
			 destOrigin: start sourceOrigin: start extent: 
			(charScanner destX - start x) @ (charScanner fontHeight)
	   		 clipRect: insetBox )
			copyBits.
		 charScanner nextline.
		 start <- charScanner destPoint.
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(BitBlt destForm: Display sourceForm: nil halftoneForm: Form black
        	combinationRule: Form reverse destOrigin: start
	    	sourceOrigin: start extent: 
		(charScanner destX - start x) @ (charScanner fontHeight)
	   	 clipRect: insetBox )
		copyBits. 
	
! !

! TextView methodsFor: 'mouse-action' !

getSelection
	| selection |
	selectStart isNil ifTrue: [ ^ cutbuffer ].
	selection <- buffer species new: (beforeSize - selectStart).
	selection replaceFrom: 1 to: selection size with: buffer
		startingAt: selectStart + 1.
	^ selection
!

again
!

undo
!

copySelect
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [
		self reverseSelection.
		selectStart <- nil.
	]
!

cut
	" Check if we have a selection. "
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [ ^ self ].
	self deleteBefore: (beforeSize - selectStart).
	selectStart <- nil.
!

paste
	self clearSelection.
	cutbuffer isNil ifFalse: [ self insertString: cutbuffer ].
!

doit
	| cmd |
	cmd <- self getSelection.
	Compiler evaluate: cmd.
!

printit
	| cmd result sel |
	cmd <- self getSelection.
	self clearSelection.
	result <- (Compiler evaluate: cmd) printString.
	sel <- beforeSize.
	self insertString: result.
	selectStart <- sel.
	self reverseSelection.
!

keypress: aKey
    | aStream aChar moveChar aString |
    aChar <- aKey asCharacter.
    Character cr = aChar ifTrue: [ aChar <- Character nl ].
    Character backspace = aChar ifTrue: [
	self deleteBefore: 1.
	^ aKey
    ].
    aKey = 127 ifTrue: [ 
	self deleteAfter: 1.
	^ aKey
    ].
    aKey = 128 ifTrue: [
	" Begining of line "
	self setInsertPoint: (lineStart at: currentLine).
	^ aKey
    ].
    aKey = 129 ifTrue: [
	" Left "
	self setInsertPoint: beforeSize - 1.
	^ aKey
    ].
    aKey = 130 ifTrue: [
	" up "
	^ aKey
    ].
    aKey = 131 ifTrue: [
	" Right "
	self setInsertPoint: beforeSize + 1.
	^ aKey
    ].
    aKey = 132 ifTrue: [
	" Down "
	^ aKey
    ].
    aKey = 133 ifTrue: [
	" Page Up "
	^ aKey
    ].
    aKey = 134 ifTrue: [
	" Page Down "
	^ aKey
    ].
    aKey = 135 ifTrue: [
	" End "
	self setInsertPoint: (lineStart at: currentLine + 1).
	^ aKey
    ].
    aKey = 136 ifTrue: [
	" Begin "
	self setInsertPoint: 0.
	^ aKey
    ].
     self insertString: aChar asString.
    ^aKey
!

setSelectionFrom: newPoint
    | newStart temp |
    newStart <- self pointToIndex: newPoint.
    self reverseSelection.
    newStart > selectStart ifTrue: [ 
	self setInsertPoint: newStart.
     ] ifFalse: [
	 selectStart <- newStart.
     ].
     self reverseSelection.
!

setInsertPointFrom: newPoint
    | aPoint line temp moreText second lineLen  |
    self clearSelection.
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: (0@0 extent: insetBox extent) offset: 0.
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue:
		 [ lineLen <- beforeSize + 1].

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].


    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    self setInsertPoint: temp.
    selectStart <- temp.
!

setCurrentInsert
    | aString x y leftString rightString |
	^self.
    x <- insertPoint x // SystemFontWidth.
    y <- insertPoint y + textTop // SystemFontHeight.
    [ lineStart size <= y ]
        whileTrue: [ lineStart add: '' ].
    "lineNumber <- y + 1.
    aString <- lineStart at: lineNumber."
    leftString <- aString copyFrom: 1 to: x.
    rightString <- aString copyFrom: x + 1 to: aString size.
    currentLine at: 1 put: (WriteStream on: (String new: 0)).
    (currentLine at: 1) nextPutAll: leftString.
    currentLine at: 2 put: (WriteStream on: (String new: 0)).
    (currentLine at: 2) nextPutAll: rightString
! !

! TextView methodsFor: 'accessing' !

contents
    | aString |
    " Copy aString to work buffer "
    aString <- buffer species new: afterSize + beforeSize.
    aString replaceFrom: 1 to: beforeSize 
	with: buffer startingAt: 1.
    aString replaceFrom: beforeSize + 1 to: beforeSize + afterSize
	with: buffer startingAt: beforeSize + 1.
    ^aString
! !

! TextView methodsFor: 'scrolling' !

scrollTo: anInteger
    textTop <- anInteger.
    textTop > textHeight
        ifTrue: [ textTop <- textHeight ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    self showText
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !

! TextView methodsFor: 'updating' !

cancel
    self setContentsFrom: original.
!

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ original <- self contents.
	     model preform: change with: original with: controller ]
! !

! TextView methodsFor: 'private' !

indexToPoint: aIndex
   | line start temp lineLen second moreText |

   " Compute line number of aIndex "
   line <- 1.
   1 to: lineStart size do: [:i |
	(lineStart at: i) < aIndex ifTrue: [ line <- i ].
   ].

    " Recompute carret "
    start <- lineStart at: line.
   " normalize to scrolling top "
    temp <- (lineHeight at: line) - textTop.
    
 
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.
    "charScanner destY: (insetBox top + temp). "

    charScanner textPos: start.

    " Check if at insert point "
    start == aIndex ifTrue: [ ^ charScanner destPoint ].

    lineLen <- aIndex.
    second <- true.
    (lineLen > beforeSize and: [ start <= beforeSize ]) ifTrue: [
	second <- false.
	 lineLen <- beforeSize ].
    " Scan rest of line "
    moreText <- true.
    [ moreText ] whileTrue: [
	
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun ] whileFalse: [
	  temp == #stopX ifTrue: [ charScanner nextline ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- aIndex.
	] ifFalse: [ moreText <- false ].
    ].
    ^ charScanner destPoint
!

pointToIndex: newPoint
    | aPoint line temp moreText second lineLen  |
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner startX: 0.
    charScanner stopX: aPoint x.
    charScanner width: insetBox width.
    charScanner height: insetBox height.
    charScanner destX: 0.
    charScanner destY: 0. 
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].


    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    ^ temp
!

defaultGapSize
       ^ 10
!

setGap: aInteger
      | newSize newBuffer temp |
      " Don't bother if gap already large enough "
     gapSize > aInteger ifTrue: [ ^ self ].
     newSize <- aInteger max: self defaultGapSize.
     newBuffer <- buffer species new: beforeSize + afterSize + newSize.
     beforeSize > 0 ifTrue: [
    	newBuffer replaceFrom: 1 to: beforeSize with: buffer
	startingAt: 1
	].
     1 to: newSize do: [ :i | newBuffer at: beforeSize + i put: $& ].
     afterSize > 0 ifTrue: [
    	newBuffer replaceFrom: beforeSize + newSize to: newBuffer size
		 with: buffer startingAt: beforeSize + gapSize + 1 ].
	" Readjust start line vector "
	1 to: lineStart size do: [ :i |
		temp <- lineStart at: i.
		temp > (beforeSize + gapSize) ifTrue:
			[ lineStart at: i put:  temp + newSize ].
	].
	buffer <- newBuffer.
	charScanner text: buffer.
	gapSize <- newSize.
! !

! TextView methodsFor: 'editing' !

setInsertPoint: aPosition
     " Set insert point to a given spot. "
    | distance gapEnd newPoint temp start |

    " Sanity check new position "
    newPoint <- aPosition.
    newPoint < 0 ifTrue: [ newPoint <- 0 ].
    newPoint > (beforeSize + afterSize) ifTrue: [ newPoint <- beforeSize + afterSize ].
    gapEnd <- beforeSize + gapSize.
    (newPoint == gapEnd or: [ newPoint == beforeSize ] ) ifTrue: [ ^ self ].

    " Clear old carret if set "
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    insertPoint <- nil.
    " Check if we need to move forward or backward in text "
    newPoint < beforeSize ifTrue: [
	" Move towards front of document. "
	distance <- beforeSize - newPoint.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: newPoint + 1.
	buffer replaceFrom: gapEnd - distance to: gapEnd - 1 with: temp startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + 1.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp > newPoint and: [ temp < gapEnd ]) ifTrue:
			[ lineStart at: t put: temp + gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - 1.
                afterSize <- afterSize + distance.
     ] ifFalse: [
	" Move towards back of document. "
	distance <- newPoint - beforeSize.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: gapEnd.
	buffer replaceFrom: beforeSize + 1 to: beforeSize + 1 + distance
		with: temp startingAt: 1.
	buffer replaceFrom: beforeSize + 1 + distance to: gapEnd + distance - 1 with: '##########' startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + gapSize.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp < newPoint and: [ temp > (beforeSize + 1) ]) ifTrue:
			[ lineStart at: t put: temp - gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - gapSize.
	afterSize <- afterSize - distance.
     ].
     beforeSize <- newPoint.
     


    " Set up scanner. "

    " Recompute carret "
    start <- lineStart at: currentLine.
   " normalize to scrolling top "
    temp <- (lineHeight at: currentLine) - textTop.

    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.

    charScanner textPos: start.

    " Check if at insert point "
    start == (beforeSize + 1) ifFalse: [
       [ temp <- charScanner scanword: beforeSize.
          temp == #endRun ] whileFalse: [
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
       ].

    insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
   InsertPoint displayOn: Display at: insertPoint
		  clippingBox: insetBox rule: Form reverse.
!

reformatAfter
    | start end second last line lineLen temp textBottom moreText
	newStart newHeight |
    " Set up scanner. "
    newStart <- OrderedCollection new.
    newHeight <- OrderedCollection new.

    " Clear cursor "
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    " Copy stuff before we changed it "
    1 to: currentLine do: [ :i |
	newStart add: (lineStart at: i ).
	newHeight add: (lineHeight at: i).
    ].
    textBottom <- textTop + insetBox height.
    " Do dirty work of displaying text "
    line <- currentLine.
    start <- newStart at: currentLine.
    temp <- (lineHeight at: currentLine) - textTop.
    
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    charScanner setRect: insetBox offset: temp.

    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    second ifFalse: [ lineLen <- beforeSize ]
    	   ifTrue: [ lineLen <- buffer size  ].

    charScanner textPos: start.

    " Check if at insert point "
    start > lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- buffer size.
    ]. 
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: lineLen.
          temp == #endRun ] whileFalse: [
	    temp == #stopX ifTrue: [
		newHeight add: charScanner destY.
		newStart add: charScanner textPos.
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	     ].
             temp == #nl ifTrue: [
		newHeight add: charScanner destY.
		newStart add: (charScanner textPos + 1).
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	
	second not ifTrue: [
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- buffer size.
		afterSize == 0 ifTrue: [ moreText <- false ].
	] ifFalse: [
		moreText <- false 
	].
    ].

    newHeight add: charScanner destY.
    charScanner nextline.
    newStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
 
    lineHeight <- newHeight.
    lineStart <- newStart.
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

deleteAfter: aNumber
	" Delete aNumber characters after insert point. "
     | amount |
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > afterSize ifTrue: [ amount <- afterSize ].
     afterSize <- afterSize - amount.
     gapSize <- gapSize + amount.
     self reformatAfter.
!

deleteBefore: aNumber
	" Delete aNumber characters before insert point. "
     | amount |
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > beforeSize ifTrue: [ amount <- beforeSize ].
     beforeSize <- beforeSize - amount.
     gapSize <- gapSize + amount.
     currentLine <- 1.
     1 to: lineStart size do: [ :i |
	(lineStart at: i) < beforeSize ifTrue: [ currentLine <- i]. ].
     self reformatAfter.
!

insertString: aString
     | newSize |
     newSize <- aString size.
     self setGap: newSize.
     buffer replaceFrom: beforeSize + 1 to: beforeSize + newSize + 1
		 with: aString startingAt: 1.
     beforeSize <- beforeSize + newSize.
     gapSize <- gapSize - newSize.
     selectStart <- nil.
     self reformatAfter.
! !

TextView initialize !

