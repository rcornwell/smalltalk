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
    italic ifTrue: [name <- name, 'i'].
    " Fill in some generic stop conditions. "
    stopConditions at: (Character backspace asciiValue + 1) put: #backspace.
    stopConditions at: (Character tab asciiValue + 1) put: #tab.
    stopConditions at: (Character cr asciiValue + 1) put: #carriageReturn.
    stopConditions at: (Character nl asciiValue + 1) put: #newLine.
    stopConditions at: (Character space asciiValue + 1) put: #space.
    stopConditions at: (Character newPage asciiValue + 1) put: #newPage.
    stopConditions at: (Character esc asciiValue + 1) put: #esc.
! !

! StrikeFont class methodsFor: 'instance creation' !

fromBDFFile: stream
    ^self new setFromBDFFile: stream
! !

