
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
    exceptions at: 257 put: #stopX.
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

! Number class methodsFor: 'Reading' !

readFrom: aStream
   | base integer fraction sign exp char multi eseen fseen dig done value |
   char <- aStream next.
   sign <- false.
   integer <- 0.
   fraction <- 0.0.
   base <- 10.
   exp <- 0.
   eseen <- false.
   fseen <- false.
   " If first char is minus check if number following "
   char = $- ifTrue: [ sign <- true.  char <- aStream next ].

   " Scan first part of number. "
   done <- true.
   [ done and: [char isDigit or: [ char isUppercase or: [ char = $r ]]]]
      whileTrue: [
	char = $r ifTrue: [
       		base <- integer.
		integer <- 0.
		done <- true.
		char <- aStream next
	 ] ifFalse: [
        	dig <- char digitValue.
         	dig > base
           		ifTrue: [ done <- false ]
		        ifFalse: [
     			     integer <- (integer * base) + dig.
			     char <- aStream next
			]
	]
   ].

   " Check if fractional value "
    char = $. ifTrue: [
	char <- aStream peek.
	" Check if period at end of line "
	(char isDigit or: [ char isUppercase ]) ifTrue: [
		char <- aStream next.
	        multi <- 1.0 / (base asFloat).
		done <- true.
		fseen <- true.
              " Scan fraction part of number. "
              [ done and: [ char isDigit or: [ char isUppercase ]]] whileTrue: [
		     dig <- char digitValue.
		     dig > base ifTrue: [ done <- false ]
		           ifFalse: [
       	           		fraction <- fraction + (multi * (dig asFloat)).
		   		multi <- multi / (base asFloat)
			   ].
		     char <- aStream next
              ]
	 ] ifFalse: [ char <- $. ]
    ].

   " Check if exponent "
    char = $e ifTrue: [
	char <- aStream next.
	eseen <- false.		" Grab variable for sec "
	char = $- ifTrue: [ eseen <- true. char <- aStream next ].
        " Scan exponent. "
        [ char isDigit ] whileTrue: [
	     exp <- (exp * 10) + (char digitValue).
	     char <- aStream next
        ].
	eseen ifTrue: [ exp <- exp negated ].
	eseen <- true
    ].
	
   " We read one char to many, put it back "
    aStream skip: -1.

   " Got a number now convert it to a object "
    (fseen or: [eseen]) ifTrue: [
	 value <- integer asFloat + fraction.
	 eseen ifTrue: [ value <- value raisedToInteger: exp ].
    ] ifFalse: [ value <- integer ].
    sign ifTrue: [ value <- value negated ].
    ^ value
! !

! Integer class methodsFor: 'reading' !

readFrom: aStream
   | base sign char multi dig done value |
   char <- aStream next.
   sign <- false.
   value <- 0.
   base <- 10.
   " If first char is minus check if number following "
   char = $- ifTrue: [ sign <- true.  char <- aStream next ].

   " Scan first part of number. "
   done <- true.
   [ done and: [char isDigit or: [ char isUppercase or: [ char = $r ]]]]
      whileTrue: [
   	char = $r ifTrue: [
       		base <- value.
		value <- 0.
		done <- true.
		char <- aStream next
	 ] ifFalse: [
        	dig <- char digitValue.
         	dig > base
           		ifTrue: [ done <- false ]
		        ifFalse: [
     			     value <- (value * base) + dig.
			     char <- aStream next
			]
	] 
   ].

   " We read one char to many, put it back "
    aStream skip: -1.

   " Got a number now convert it to a object "
    sign ifTrue: [ ^ value negated ]
    	 ifFalse: [ ^ value ]
! !

Object subclass: 'StrikeFont'
       instanceVariableNames: 'name size bold italic stopConditions xTable minAscii maxAscii maxWidth ascent descent raster superscript subscript height'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Graphic-Kernel' !

! StrikeFont methodsFor: 'accessing' !

name
	^ name
!

size
	^ size
!

bold
	^ bold
!

italic
	^ italic
!

ascent
	^ ascent
!

descent
	^ descent
!

height
	^ height
!

superscript
	^ superscript
!

subscript
	^ subscript
!

raster
	^ raster
!

xTable
	^ xTable
!

stopConditions
	^ stopConditions
! !

! StrikeFont methodsFor: 'private'!

setFromBDFFile: stream
     "Create a StrikeFont from an X11 style Bitmap Distribution Format file."

     | token cr separators blitter byteStripe glyph glyphs min max  
	ascii charWidth w h ox oy bytes width line val index char rev |

    bold <- italic <- false.
    rev <- #( 0 8 4 12 2 10 6 14 1 9 5 13 3 11 7 15 ).
    stopConditions <- Array new: 258.
    stopConditions atAllPut: #characterNotInFont.
    glyphs <- Array new: 256.
    xTable <- Array new: 258.
    xTable atAllPut: 0.
    minAscii <- 0.
    maxAscii <- 255.
    min <- 256.
    max <- -1. 
    maxWidth <- 0.
    width <- 0.
    byteStripe <- Form extent: 1024@1.
    glyph <- Form extent: 0@0.
    blitter <- BitBlt destForm: glyph
		       sourceForm: byteStripe
		       halftoneForm: nil
		       combinationRule: Form over
    		       destOrigin: 0@0
		       sourceOrigin: 0@0
		       extent: 0@1
		       clipRect: (0@0 extent: 0@0). 

    cr <- Character nl.
    separators <- Array with: Character space with: cr.
    [stream atEnd] whileFalse: [
    	token <- stream upToAny: separators.
    	token = 'STARTPROPERTIES' ifTrue: [
    	[  stream skip: -1; skipTo: cr.
    	   token <- stream upToAny: separators.
  	   token = 'ENDPROPERTIES'] whileFalse: [
    	   token = 'FONT_ASCENT'
		 ifTrue: [ascent <- Integer readFrom: stream].
    	   token = 'FONT_DESCENT'
		 ifTrue: [descent <- Integer readFrom: stream].
    	   token = 'FAMILY_NAME'
		 ifTrue: [stream skipTo: $".  name <- stream upTo: $"].
    	   token = 'WEIGHT_NAME'
		 ifTrue: [stream skipTo: $". bold <- stream peek = $B].
    	   token = 'SLANT'
		 ifTrue: [stream skipTo: $". 
			  italic <- stream peek == $I or:
					 [stream peek == $O]].
    	   token = 'PIXEL_SIZE'
		 ifTrue: [size <- Integer readFrom: stream ].
 	   ].
	 name printOn: stderr. stderr space.
	 bold printOn: stderr. stderr space.
	 italic printOn: stderr. stderr space.
	 size printOn: stderr. stderr space.
	 stderr nl.
    	height <- ascent + descent.
    	blitter clipHeight: (ascent + descent)].

    	token = 'STARTCHAR' ifTrue: [
	    stream skip: -1; skipTo: cr.
    	    ((token <- stream upToAny: separators) = 'ENCODING'
    	        and: [(ascii <- Integer readFrom: stream) > 0]) ifTrue: [
    		ascii < min ifTrue: [min <- ascii].
    		ascii > max ifTrue: [max <- ascii].
    		stopConditions at: ascii + 1 put: nil.
    		[   stream skip: -1; skipTo: cr.
    		    token <- stream upToAny: separators.
   		    token = 'ENDCHAR'] whileFalse: [
    		    token = 'DWIDTH' ifTrue: 
		        [charWidth <- Integer readFrom: stream].
    		    token = 'BBX' ifTrue: [
    			w <- Integer readFrom: stream.
			stream skip: 1.
    			h <- Integer readFrom: stream.
		        stream skip: 1.
    			ox <- Integer readFrom: stream.
			stream skip: 1.
    			oy <- Integer readFrom: stream.
    			glyph <- Form extent: (w + 1 max: charWidth) @
				 height; white.
    			maxWidth < glyph width ifTrue:
				 [maxWidth <- glyph width].
			width <- glyph width + width.
			blitter destForm: glyph; width: w; clipWidth: w].
    		    token = 'BITMAP' ifTrue: [
    			stream skip: -1; skipTo: cr.
    			0 to: h - 1 do: [:y |
			    index <- 0.
			    val <- 0.
			    [ char <- stream next.
			      char ~= cr ] whileTrue: [
			        char <- rev at: (1 + char digitValue).
				char <- char bitShift: (4 * (index \\ 4)).
				val <- val + char.
				index <- index + 1.
				index \\ 4 == 0 ifTrue: [
    					byteStripe bitmap at: (index // 4)
							 put: val.
					val <- 0.
				].
			     ].
			     [ index \\ 4 ~= 0 ] whileTrue: [
				index <- index + 1.
			     ].
			     byteStripe bitmap at: (index // 4) put: val.
    			     blitter destY: ascent - h - oy + y; copyBits
			].
    			glyphs at: ascii put: glyph.
    			].
 		]].
	].
         stream skip: -1; skipTo: cr. ].

    raster <- Form extent: width @ height.
    blitter <- BitBlt destForm: raster
		       sourceForm: glyph
		       halftoneForm: nil
		       combinationRule: Form over
    		       destOrigin: 0@0
		       sourceOrigin: 0@0
		       extent: width@height
		       clipRect: (0@0 extent: width@height). 
    1 to: glyphs size do: [ :i |
	glyph <- glyphs at: i.
	xTable at: (i + 1) put: blitter destX.
	glyph isNil ifFalse: [
	    blitter sourceForm: glyph.
	    blitter copyBits.
	    blitter destX: (blitter destX + (glyph width) + 1).
	].
    ].
    xTable at: 257 put: blitter destX.
    superscript <- ascent - descent // 3.	
    subscript <- descent - ascent // 3.
    minAscii <- min.
    maxAscii <- max.
    bold ifTrue: [name <- name, 'b'].
    italic ifTrue: [name <- name, 'i']
! !

! StrikeFont class methodsFor: 'instance creation' !

fromBDFFile: stream
    ^self new setFromBDFFile: stream
! !

Object subclass: 'Font'
       instanceVariableNames: 'name size font bold italic' 
       classVariableNames: 'FontFamilies SystemFont'
       poolDictionaries: ''
       category: 'Graphic-Kernel' !

! Font class methodsFor: 'access' !

systemFont
	^ self new systemFont
!

family: aName
	^ self new family: aName
!

family: aName size: aSize
	^ self new family: aName size: aSize
! !

! Font methodsFor: 'access' !

systemFont
	| family f |
	font <- SystemFont.
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
!

family: aName
	| family f |
	family <- FontFamilies at: aName asSymbol ifAbsent: [ nil ].
	family isNil ifFalse: [ family do: [ :e | font <- e ] ]
	    ifTrue: [ font <- SystemFont ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
!

family: aName size: aSize
	| family f |
	family <- FontFamilies at: aName asSymbol ifAbsent: [ nil ].
	family isNil ifFalse: [
	    font <- family at: aSize ifAbsent: [ nil ].
	    font isNil ifTrue: [ family do: [ :e | font <- e ] ].]
	    ifTrue: [ font <- SystemFont ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
!

size: aSize
	| family f |
	family <- FontFamilies at: name asSymbol ifAbsent: [ nil ].
	font <- family at: size ifAbsent: [ font ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
!

normal
	bold <- false.
	italic <- false.
!

bolditalic
	bold <- true.
	italic <- true.
!

bold
	bold <- true.
!

italic
	italic <- true.
!

nobold
	bold <- false
!

noitalic
	italic <- false
!

size
	^ size
!

name
	^ name
!

style: aStyle
	aStyle == #Bold ifTrue: [ ^ self bold ].
	aStyle == #Italic ifTrue: [ ^ self italic ].
	aStyle == #BoldItalic ifTrue: [ ^ self bolditalic ].
	^ self normal
!

font
	| index |
	index <- 1.
	italic ifTrue: [ index <- index + 1 ].
	bold ifTrue:  [ index <- index + 2 ].
	^ font at: index
! !

! Font methodsFor: 'private' !

setSystem
	SystemFont <- font.
! !

! Font class methodsFor: 'creation' !

newFamily: aName
	| font |
	FontFamilies isNil ifTrue: [ FontFamilies <- Dictionary new ].
	font <- FontFamilies at: aName asSymbol ifAbsent: [ nil ].
	font isNil ifTrue: [
		font <- OrderedCollection new.
		FontFamilies at: aName asSymbol put: font
	].
!

add: aFont
	| index family font |
	FontFamilies isNil ifTrue: [ FontFamilies <- Dictionary new ].
	family <- FontFamilies at: aFont name asSymbol ifAbsent: [
		family <- Dictionary new.
		FontFamilies at: aFont name asSymbol put: family.
		family
	].
	font <- family at: aFont size ifAbsent: [ 
		font <- Array new: 4.
		family at: aFont size put: font.
		font
	].
	index <- 1.
	aFont italic ifTrue: [ index <- index + 1 ].
	aFont bold ifTrue: [ index <- index + 2 ].
	font at: index put: aFont.
! !

! Font class methodsFor: 'initialize' !

initialize
   | dir name dname stream font |
   dname <- 'fonts'.
   dir <- (File name: dname ) directory.
   dir do: [ :fn |
	name <- ReadStream on: fn.
	((name skipTo: $. ) and: [
	     (name peekFor: $B) and: [
	     (name peekFor: $D) and: [
	     (name peekFor: $F) ]]]) ifTrue: [
		name <- dname, '/', fn.
	       stream <- FileStream on: name.
	       font <- StrikeFont fromBDFFile: stream.
	       Font add: font.
	       stream close
	]
    ].
    (Font family: 'Courier' size: 10) setSystem
! !

Font initialize !

"Added some methods to class String to display a string on a Form" !

! String methodsFor: 'displaying' !

display
    ^Display displayString: self at: 0@0
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayAt: aPoint
    ^Display displayString: self at: aPoint
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm
    ^aForm displayString: self at: 0@0
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
    ^aForm displayString: self at: aPoint
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
    ^aForm displayString: self at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
! !

! Form methodsFor: 'displaying text' !

displayString: aString at: aPoint
                 clippingBox: clipRectangle
                 rule: rule
                 mask: mask
    | scanner code |
    scanner <- CharacterScanner text: aString 
	destForm: self font: Font systemFont
        combinationRule: rule destOrigin: aPoint
        extent: ((self width)@(self height)) clipRect: clipRectangle.
    scanner stopcode: (Character backspace asciiValue + 1)  put: #bs.
    scanner stopcode: (Character tab asciiValue + 1) put: #tab.
    scanner stopcode: (Character cr asciiValue + 1) put: #nl.
    scanner stopcode: (Character nl asciiValue + 1) put: #nl.
    [ code <- scanner scanword: aString size.
      code == #endRun ] whileFalse: [
	(code == #stopX or: [ code == #nl ]) ifTrue: [ scanner nextline ].
	code == #bs ifTrue: [ scanner backspace ].
	code == #tab ifTrue: [ scanner tab ].
    ].
! !

! Form methodsFor: 'initialize-release' !

fromString: aString 
    | extent |
    extent <- aString displayExtent.
    self extent: extent.
    self displayString: aString at: 0@0
                 clippingBox: (Rectangle origin: 0@0 corner: extent)
                 rule: Form over
                 mask: Form black
! !
 
! String methodsFor: 'display sizing' !

displayExtent
    | scanner code width |
    width <- 0.
    scanner <- CharacterScanner text: self 
	destForm: Display font: Font systemFont.
    scanner printing: false.
    scanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    scanner stopcode: (Character tab asciiValue + 1) put: #tab.
    scanner stopcode: (Character cr asciiValue + 1) put: #nl.
    scanner stopcode: (Character nl asciiValue + 1) put: #nl.
    [ code <- scanner scanword: self size.
      code == #endRun ] whileFalse: [
	width <- width max: scanner destX.
	(code == #stopX or: [ code == #nl ]) ifTrue: [ scanner nextline ].
	code == #bs ifTrue: [ scanner backspace ].
	code == #tab ifTrue: [ scanner tab ].
    ].
    width <- width max: scanner destX.
    scanner nextline.
    ^ width @ scanner destY
! !

