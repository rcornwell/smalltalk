
Collection subclass: 'Text'
	instanceVariableNames: 'string runs'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections'
!

!Text class methodsFor:'instance creation'!

fromString:aString 
    "create a Text instance, for the characters in aString,
     without emphasis."
    ^ super new string:aString emphasis:nil

    " Text fromString:'hello'
    "
!

new
    "create a new empty Text instance.
     Redefined for string-protocol compatibility"
    ^ super new string:(String new) emphasis:nil

    "Text new"
!

new:size
    "create a new empty Text instance.
     Redefined for string-protocol compatibility"

    ^ self string:(String new:size)
!

string:aString 
    "create a Text instance, for the characters in aString,
     without emphasis."

    ^ super new string:aString emphasis:nil

    "
     Text string:'hello'
    "
!

string:aString emphasis:attribute
    "create a Text instance, for the characters in aString,
     which are emphasized as described by attribute."

    ^ super new string:aString emphasis:attribute

    "
     Text string:'hello' emphasis:#bold
    "
!

string:aString emphasisCollection:attributeCollection
    "create a Text instance, for the characters in aString,
     which are individually emphasized as described by attributeCollection."

    ^ super new string:aString emphasisCollection:attributeCollection

    "
     Text 
        string:'hello' 
        emphasisCollection:#(#bold #bold #italic #italic #italic)
!

string:aString runs:aRun
    "create a Text instance, for the characters in aString,
     which are individually emphasized as described by attributeCollection."

    ^ super new string:aString emphasisCollection:aRun.
! !

!Text class methodsFor:'emphasis helper'!

addEmphasis:e1 to:e2
    "merge two emphasis's into one"

    |ne|

    e1 isNil ifTrue:[^ e2].
    e2 isNil ifTrue:[^ e1].
    e1 == e2 ifTrue:[^ e1].

    (e1 isSymbol 
     or:[e1 isAssociation]) ifTrue:[
        (e2 isSymbol 
         or:[e2 isAssociation]) ifTrue:[
            ^ Array with:e1 with:e2
        ].
        (e2 includes:e1) ifTrue:[^ e2].
        ^ e2 copyWith:e1
    ].
    (e2 isSymbol 
     or:[e2 isAssociation]) ifTrue:[
        (e1 includes:e2) ifTrue:[^ e1].
        ^ e1 copyWith:e2
    ].

    ne <- e1.
    e2 do:[:e |
        (ne includes:e) ifFalse:[
           ne <- ne copyWith:e
        ]
    ].
    ^ ne.

    "
     Text addEmphasis:#bold to:#bold           
     Text addEmphasis:#bold to:#italic         
     Text addEmphasis:#bold to:#(italic strikeout)   
     Text addEmphasis:#italic to:#(italic strikeout) 
     Text addEmphasis:#(italic strikeout) to:#bold  
     Text addEmphasis:#(italic strikeout) to:#italic 
     Text addEmphasis:#(italic strikeout) to:#(bold underline) 
    "
!

emphasis:e1 includes:e2
    "return true, if e1 includes e2.
     e2 should be a single emphasis."

    e1 isNil ifTrue:[^ false].
    e2 isNil ifTrue:[^ false].
    e1 == e2 ifTrue:[^ true].

    (e1 isSymbol 
     or:[e1 isAssociation]) ifTrue:[
        ^ false
    ].
    (e2 isSymbol 
     or:[e2 isAssociation]) ifTrue:[
        ^ (e1 includes:e2)
    ].
    ^ false

    "
     Text emphasis:#bold includes:#bold           
     Text emphasis:#bold includes:#ialic         
     Text emphasis:#(italic strikeout) includes:#bold  
     Text emphasis:#(italic strikeout) includes:#italic 
    "
!

extractEmphasis:key from:e
    "if key is included in the emphasis, e then return the key.
     Otherwise, if a n association with that key is included, return the value.
     Otherwise, return nil."

    e isNil ifTrue:[^ nil].
    key == e ifTrue:[^ e].

    e isAssociation ifTrue:[
        e key == key ifTrue:[^ e value].
        ^ nil
    ].
    (e includes:key) ifTrue:[^ key].
    e do:[:entry | 
        entry isAssociation ifTrue:[
            entry key == key ifTrue:[
                ^ entry value
            ]
        ]
    ].
    ^ nil

    "
     Text extractEmphasis:#bold  from:#bold           
     Text extractEmphasis:#bold  from:#italic           
     Text extractEmphasis:#bold  from:#(italic strikeout)           
     Text extractEmphasis:#bold  from:#(italic bold)           
    "
!

removeEmphasis:e1 from:e2
    "remove an emphasis; if it was not in e1, do nothing"

    |ne|

    e1 isNil ifTrue:[^ nil].
    e2 isNil ifTrue:[^ e1].
    e1 == e2 ifTrue:[^ nil].

    (e2 isSymbol 
     or:[e2 isAssociation]) ifTrue:[
        (e1 includes:e2) ifTrue:[^ nil].
        ^ e2
    ].
    (e1 isSymbol 
     or:[e1 isAssociation]) ifTrue:[
        (e2 includes:e1) ifTrue:[
            ne <- e2 copyWithout:e1.
            ne size == 1 ifTrue:[^ ne at:1].
            ne size == 0 ifTrue:[^ nil].
            ^ ne
        ].
        ^ e2
    ].

    "/ ould use:
    "/    ^ (e2 asSet removeAll:e1; asArray)

    "/ but we do it manually, to preserve the
    "/ order. (should create longer runs, while editing)

    ne <- e2.
    e1 do:[:e |
        (ne includes:e) ifTrue:[
           ne <- ne copyWithout:e
        ]
    ].
    ne size == 1 ifTrue:[^ ne at:1].
    ne size == 0 ifTrue:[^ nil].
    ^ ne.

    "
     Text removeEmphasis:#bold from:#bold           
     Text removeEmphasis:#bold from:#italic         
     Text removeEmphasis:#bold from:#(italic strikeout)   
     Text removeEmphasis:#italic from:#(italic strikeout) 
     Text removeEmphasis:#(italic strikeout) from:#bold  
     Text removeEmphasis:#(italic strikeout) from:#italic  
     Text removeEmphasis:#(italic strikeout) from:#(bold underline) 
     Text removeEmphasis:#(italic strikeout bold) from:#(bold underline) 
     Text removeEmphasis:#(italic strikeout bold underline) from:#(bold underline) 
    "
! !

!Text methodsFor:'comparing'!

= aStringOrText
    "compare the receiver and the argument, ignoring emphasis"

    aStringOrText isString ifFalse:[^ false].
    ^ string = aStringOrText string


    "
     'hello' asText = 'hello'        
     'hello' asText = 'hello' asText 
     'hello' asText allBold = 'hello' 
    "
! !

!Text methodsFor:'converting'!

asText
    "return the receiver itself - it is already a text object"

    ^ self
! !

!Text methodsFor:'copying'!

, aStringOrText
    "concatenate the receivers characters with the arguments characters, 
     and return string or text object containing those characters.
     If either the receiver or the argument contains emphasis information,
     a text object will be returned. Otherwise, a string (i.e. without emphasis)
     is returned."

    |newRuns|

    aStringOrText hasChangeOfEmphasis ifTrue:[    
        ^ self species new
            string:(string , aStringOrText)
            emphasisCollection:(runs , aStringOrText emphasisCollection)
    ].
    runs notNil "self hasChangeOfEmphasis" ifTrue:[ 
        newRuns <- runs copyFrom:1 to:(runs size).
        
        ^ self species new
            string:(string , aStringOrText)
            emphasisCollection:(newRuns add:nil withOccurrences:(aStringOrText size); yourself)
    ].
    ^ string , aStringOrText string

    "
     ('hello' asText allBold) , ' world'    
     'hello' , (' world' asText allBold)
     'hello' , ' world'
     ('hello' asText allBold) , (' world' asText allBold)
    "
!

concatenateFromString:aString
    "return the concatenation of aString and myself.
     This may be a Text (if I have emphasis) or a string (if not)."

    self hasChangeOfEmphasis ifTrue:[
        ^ self species new
                string:(aString , string)
                emphasisCollection:((RunArray new:(aString size)) , runs).
    ].
    ^ aString , string
!

copyFrom:start to:stop
    "return the subcollection starting at index start, anInteger and ending
     at stop, anInteger."

    self hasChangeOfEmphasis ifTrue:[
        ^ self species new
                string:(string copyFrom:start to:stop)
                emphasisCollection:(runs copyFrom:start to:stop).
    ].
    ^ string copyFrom:start to:stop
!

postCopy
    string <- string copy.
    runs <- runs copy
! !

!Text methodsFor:'displaying'!

displayOn:aGC x:x0 y:y opaque:opaque
    "display the receiver on a GC"

    |savedFont savedPaint savedBgPaint font color boldFont italicFont boldItalicFont 
     bgPaint
     bold italic underline strikeout 
     pos    "{ Class: SmallInteger }"
     endPos "{ Class: SmallInteger }"
     x      
     l      "{ Class: SmallInteger }"
     yL k value device|

    savedFont <- aGC basicFont.
    savedPaint <- aGC paint.
    savedBgPaint <- aGC backgroundPaint.

    pos <- 1.
    x <- x0.
    runs runsDo:[:len :emphasis |
        color <- nil.
        bold <- italic <- underline <- strikeout <- false.
        bgPaint <- savedBgPaint.

        emphasis isSymbol ifTrue:[
            emphasis == #bold ifTrue:[bold <- true]
            ifFalse:[emphasis == #italic ifTrue:[italic <- true]
            ifFalse:[emphasis == #underline ifTrue:[underline <- true]
            ifFalse:[emphasis == #strikeout ifTrue:[strikeout <- true]
            ]]]
        ] ifFalse:[
            (emphasis isMemberOf:Association) ifTrue:[
                value <- emphasis value.
                k <- emphasis key.
                k == #color ifTrue:[
                    color <- value
                ] ifFalse:[k == #backgroundColor ifTrue:[
                    bgPaint <- value
                ]]
            ] ifFalse:[
                emphasis notNil ifTrue:[
                    emphasis do:[:entry |
                        entry == #bold ifTrue:[bold <- true]
                        ifFalse:[entry == #italic ifTrue:[italic <- true]
                        ifFalse:[entry == #underline ifTrue:[underline <- true]
                        ifFalse:[entry == #strikeout ifTrue:[strikeout <- true]
                        ifFalse:[
                            (entry isMemberOf:Association) ifTrue:[
                                value <- entry value.
                                k <- entry key.
                                k == #color ifTrue:[
                                    color <- value
                                ] ifFalse:[k == #backgroundColor ifTrue:[
                                    bgPaint <- value
                                ]]
                            ]
                        ]]]]
                    ]
                ]
            ]
        ].

        device <- aGC graphicsDevice.

        color isNil ifTrue:[
            color <- savedPaint.
        ] ifFalse:[
            color <- color on:device.
        ].

        bold ifTrue:[
            italic ifTrue:[
                boldItalicFont isNil ifTrue:[
                    boldItalicFont <- savedFont asBold asItalic on:device
                ].
                font <- boldItalicFont.
            ] ifFalse:[
                boldFont isNil ifTrue:[
                    boldFont <- savedFont asBold on:device
                ].
                font <- boldFont.
            ]
        ] ifFalse:[
            italic ifTrue:[
                italicFont isNil ifTrue:[
                    italicFont <- savedFont asItalic on:device
                ].
                font <- italicFont.
            ] ifFalse:[
                font <- savedFont
            ]
        ].
        aGC basicFont:font.
        aGC paint:color on:bgPaint.

        endPos <- pos + len - 1.
        opaque ifTrue:[
            aGC displayOpaqueString:string from:pos to:endPos x:x y:y.
        ] ifFalse:[
            aGC displayString:string from:pos to:endPos x:x y:y.
        ].
        l <- (aGC font on:aGC device) widthOf:string from:pos to:endPos.

        underline ifTrue:[
            yL <- y+1.
            aGC displayLineFromX:x y:yL toX:x+l-1 y:yL
        ].
        strikeout ifTrue:[
            yL <- y-(font ascent//2).
            aGC displayLineFromX:x y:yL toX:x+l-1 y:yL
        ].

        x <- x + l.
        pos <- endPos + 1
    ].

    aGC basicFont:savedFont.
    aGC paint:savedPaint on:savedBgPaint.

    "Created: / 12.5.1996 / 11:14:30 / cg"
    "Modified: / 14.11.1997 / 21:49:33 / cg"
! !

!Text methodsFor:'emphasis'!

allBold
    "make all characters bold"

    self emphasizeAllWith:#bold

    "
     (Text string:'hello') allBold
    "
!

emphasis
    "return the emphasis"

    ^ runs

    "
     (Text string:'hello') allBold emphasis 
     'hello' emphasis   
    "
!

emphasisAt:characterIndex
    "return the emphasis at some index"

    ^ runs at:characterIndex

    "
     (Text string:'hello') allBold emphasisAt:2 
    "
!

emphasisAt:characterIndex add:newEmphasis
    "add to the emphasis at some index. return the receiver"

    |e prevE|

    e <- runs at:characterIndex.
    e <- self class addEmphasis:newEmphasis to:e.

    "/ if its equal to the previous emphasis, make it identical.

    characterIndex > 1 ifTrue:[
        prevE <- runs at:characterIndex-1.
        e = prevE ifTrue:[
            e <- prevE
        ]
    ].
    runs at:characterIndex put:e

    "
     (Text string:'hello') allBold emphasisAt:2 add:#italic
    "
!

emphasisAt:characterIndex put:emphasis
    "change the emphasis at some index. return the receiver"

    |e prevE|

    e <- emphasis.

    "/ if its equal to the previous emphasis, make it identical.

    characterIndex > 1 ifTrue:[
        prevE <- runs at:characterIndex-1.
        emphasis = prevE ifTrue:[
            e <- prevE
        ]
    ].
    runs at:characterIndex put:e

    "
     (Text string:'hello') allBold emphasisAt:2 put:#italic
    "
!

emphasisAt:characterIndex remove:emphasisToRemove
    "remove from the emphasis at some index. return the receiver"

    |e|

    e <- runs at:characterIndex.
    e <- self class removeEmphasis:emphasisToRemove from:e.
    runs at:characterIndex put:e

    "
     (Text string:'hello') 
        allBold emphasisAt:2 remove:#bold

     (Text string:'hello' emphasis:#(bold italic)) 
        emphasisAt:2 remove:#bold
    "
!

emphasisCollection
    "return the emphasis"

    ^ runs

    "
     (Text string:'hello') allBold emphasis 
     'hello' emphasis   
    "
!

emphasizeAllWith:emphasis
    "change the emphasis of all characters"

    runs <- RunArray new:(string size) withAll:emphasis

    "
     (Text string:'hello') allBold emphasizeAllWith:#italic 
    "
!

emphasizeFrom:start count:count with:emphasis
    "change the emphasis of a range of characters, given startIndex and count."

    self emphasizeFrom:start to:(start+count-1) with:emphasis

    "
     (Text string:'hello world') 
        emphasizeFrom:1 count:5 with:#bold;
        emphasizeFrom:7 count:5 with:#italic
    "
!

emphasizeFrom:start to:stop with:emphasis
    "change the emphasis of a range of characters"

    |newRuns|

    runs from:start to:stop put:emphasis.
^ self.

    newRuns <- RunArray new.

    "/ for now - a q&d hack
    1 to:start-1 do:[:i |
        newRuns add:(runs at:i).
    ].
    newRuns add:emphasis withOccurrences:(stop - start + 1).
    stop+1 to:string size do:[:i |
        newRuns add:(runs at:i)
    ].
    runs <- newRuns

    "
     (Text string:'hello world') 
        emphasizeFrom:1 to:5 with:#bold;
        emphasizeFrom:7 to:11 with:#italic
    "
!

emphasizeFrom:start with:emphasis
    "change the emphasis of some characters upTo the end"

    self emphasizeFrom:start to:(self size) with:emphasis

    "
     (Text string:'hello world') 
        emphasizeFrom:1 count:5 with:#bold;
        emphasizeFrom:7 with:#italic
    "
! !

!Text methodsFor:'printing & storing'!

printOn:aStream
    "print the receivers characters (including emphasis) on
     aStream. 
     Notice, that some streams simply ignore the emphasis 
     (Transcript currently does)."

    |pos nextPos|

    pos <- 1.

    runs runsDo:[:len :emphasis |
        nextPos <- pos + len.

        aStream emphasis:emphasis.
        aStream nextPutAll:string startingAt:pos to:nextPos - 1.
        pos <- nextPos
    ].

    "
     Transcript showCR:'hello world'.
     Transcript showCR:'hello world' asText allBold.
     Transcript showCR:('hello world' asText emphasizeAllWith:#italic).
    "
!

storeOn:aStream
    "append a printed representation from which the receiver can be reconstructed
     to aStream."

    aStream nextPutAll:'(Text string:'.
    string storeOn:aStream.
    aStream nextPutAll:' runs:'.
    runs storeOn:aStream.
    aStream nextPutAll:')'.
! !

!Text methodsFor:'private accessing'!

emphasisCollection:emphasisCollection
    "set the string and emphasis collection.
     The emphasis collection contains per-character information."

    runs <- emphasisCollection
!

string:aString emphasis:emphasis
    "set the string and emphasis. The emphasis is applied to all characters."

    string <- aString string.
    runs   <- RunArray new:string size withAll:emphasis

    "
     |t|

     t <- Text new string:'hello' emphasis:#bold.
     t emphasisAt:2.
    "
!

string:aString emphasisCollection:emphasisCollection
    "set the string and emphasis collection.
     The emphasis collection contains per-character information."

    string <- aString string.
    runs <- emphasisCollection asRunArray

    "
     |t|

     t <- Text new string:'hello' emphasisCollection:(#bold #bold #bold #italic #italic).
     t emphasisAt:2.
    "
! !

!Text methodsFor:'queries'!

hasChangeOfEmphasis
    "return true, if the receiver contains non-empty emphasis information"

    ^ (runs notNil
       and:[(runs findFirst:[:e | e notNil]) ~~ 0])
!

heightOn:aGC
    "return the number of device units, required on aGC's device"

    ^ (aGC font onDevice:aGC device) heightOf:string
!

indexOf:aCharacter startingAt:index
    "search aCharacters index in the underlying string"

    ^ string indexOf:aCharacter startingAt:index
!

isText
    "return true if this is a Text object - always true here"

    ^ true
!

occurrencesOf:aCharacter
    "count & return the number of occurrences of aCharacter in the 
     underlying string"

    ^ string occurrencesOf:aCharacter
!

size
    "return the number of characters in the underlying string"

    ^ string size
!

string
    "return the receiver without any emphasis information
     i.e. the underlying string."

    ^ string
!

widthOn:aGC
    "return the number of device units, required on aGC's device"

    |savedFont boldFont italicFont bold italic pos f l device|

    device <- aGC graphicsDevice.

    savedFont <- aGC basicFont on:device.

    pos <- 1.
    l <- 0.
    runs runsDo:[:len :emphasis |
        emphasis isSymbol ifTrue:[
            bold <- emphasis == #bold.
            italic <- emphasis == #italic.
        ] ifFalse:[
            (emphasis isNil 
            or:[emphasis isMemberOf:Association]) ifTrue:[
                bold <- italic <- false
            ] ifFalse:[
                bold <- emphasis includesIdentical:#bold.
                italic <- emphasis includesIdentical:#italic.
            ]
        ].

        bold ifTrue:[
            boldFont isNil ifTrue:[
                boldFont <- savedFont asBold on:device
            ].
            f <- boldFont.
        ] ifFalse:[
            italic ifTrue:[
                italicFont isNil ifTrue:[
                    italicFont <- savedFont asItalic on:device
                ].
                f <- italicFont
            ] ifFalse:[
                f <- savedFont
            ]
        ].
        f <- f onDevice:aGC device.
        l <- l + (f widthOf:string from:pos to:(pos + len - 1)).
        pos <- pos + len
    ].

    ^ l
! !

!Text methodsFor:'replacing'!

replaceFrom:start to:stop with:aCollection startingAt:startIndex
    "replace a range of characters, from another string or text object.
     The corresponding characters' emphasis information is also copied.
     Return the receiver."

    |idx|

    aCollection isString ifTrue:[
        aCollection hasChangeOfEmphasis ifTrue:[
            string replaceFrom:start to:stop with:aCollection startingAt:startIndex.
            idx <- startIndex.
            start to:stop do:[:col |
                self emphasisAt:col put:(aCollection emphasisAt:idx).
                idx <- idx + 1.
            ].
            ^ self.
        ]
    ].

    string replaceFrom:start to:stop with:aCollection startingAt:startIndex.
    self emphasizeFrom:start to:stop with:nil

    "
     ((Text string:'hello') allBold emphasisAt:2 put:#italic)
        copyFrom:1 to:3
    "
! !

