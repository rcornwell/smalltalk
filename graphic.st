
" Methods for Class graphics subclasses"

" $Id: $ "

"
 $Log: $

"

"place holders for some global objects"
Smalltalk at: #Display put: nil
!

Object subclass: 'Point'
       instanceVariableNames: 'x y'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Graphic-Kernel'
!

Point comment:
'Beginning of a Point class for simple display manipulation.  Has not been
 exhaustively tested but appears to work for the basic primitives and for
 the needs of the Rectangle class.' !

! Point class methodsFor: 'instance creation' !

x: xInteger y: yInteger
    ^self new x: xInteger y: yInteger
! !

! Point methodsFor: 'printing'!

printOn: aStream
    aStream print: x.
    aStream nextPut: $@.
    aStream print: y
! !

! Point methodsFor: 'storing'!

storeOn: aStream
    aStream store: x.
    aStream nextPut: $@.
    aStream store: y
! !

! Point methodsFor: 'accessing'!

x
    ^x
!

y
    ^y
!

x: aNumber
    x <- aNumber
!

y: aNumber
    y <- aNumber
!

x: anXNumber y: aYNumber
    x <- anXNumber.
    y <- aYNumber
! !

! Point methodsFor: 'converting'!

asPoint
    ^self			"But I already AM a point!!"
!

hash
    ^(x abs + y abs) truncated
! !

! Point methodsFor: 'arithmetic'!

+ delta
   | d |
    d <- delta asPoint.
    ^Point x: (x + d x) y: (y + d y)
!

- delta
    | d |
    d <- delta asPoint.
    ^Point x: (x - d x) y: (y - d y)
!

* scale
    | s |
    s <- scale asPoint.
    ^Point x: (x * s x) y: (y * s y)
!

/ scale
    | s |
    s <- scale asPoint.
    ^Point x: (x / s x) y: (y / s y)
!

// scale
    | s |
    s <- scale asPoint.
    ^Point x: (x // s x) y: (y // s y)
!

abs
    ^Point x: (x abs) y: (y abs)
! !

! Point methodsFor: 'truncation and round off'!
rounded
    ^Point x: (x rounded) y: (y rounded)
!

truncateTo: grid
    ^Point x: (x truncateTo: grid) y: (y truncateTo: grid)

! !

! Point methodsFor: 'comparing'!

= aPoint
    ^(x = aPoint x) and: [ y = aPoint y ]
!

< aPoint
    ^(x < aPoint x) and: [ (y < aPoint y) ]
!

> aPoint
    ^(x > aPoint x) and: [ (y > aPoint y) ]
!

<= aPoint
    ^(x <= aPoint x) and: [ (y <= aPoint y) ]
!

>= aPoint
    ^(x >= aPoint x) and: [ (y >= aPoint y) ]
!

max: aPoint
    (self >aPoint )
       ifTrue: [ ^self ]
       ifFalse:[ ^aPoint ]
!

min: aPoint
    (self < aPoint)
       ifTrue: [^ self ]
       ifFalse:[^ aPoint ]
! !

! Point methodsFor: 'point functions'!

dist: aPoint
    | a b |
    a <- x - (aPoint x).
    b <- y - (aPoint y).
    ^((a squared) + (b squared)) sqrt
!

dotProduct: aPoint
    ^(x * aPoint x) + (y * aPoint y)
!

grid: aPoint
    ^Point x: (x roundTo: (aPoint x)) y: (y roundTo: (aPoint y))
!

normal
"rotate the Point 90degrees clockwise and get the unit vector"
    |len|
    len <- ((x squared) + (y squared)) sqrt.
    ^Point x: ((y asFloat negated)/len) y: (x/len)
!

transpose
    ^Point x: y y: x
!

truncatedGrid: aPoint
    ^Point x: (x truncateTo: (aPoint x)) y: (y truncateTo: (aPoint y))
! !

! Number methodsFor: 'point creation' !

@ y
    <primitive 17>
    ^ Point x: self y: y
!

asPoint
    ^Point x: self y: self
! !

Object subclass: 'Rectangle'
       instanceVariableNames: 'origin corner'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Graphic-Kernel'
!

Rectangle comment:
'Beginning of the Rectangle class for simple display manipulation.
 Rectangles require the Point class to be available.  An extension
 to the Point class is made here that since it requires Rectangles
 to be defined (see converting)' !

! Rectangle class methodsFor: 'instance creation'!

origin: originPoint corner: cornerPoint
    ^self new origin: originPoint corner: cornerPoint
!

origin: originPoint extent: extentPoint
    ^self new origin: originPoint corner: (originPoint + extentPoint)
!

left: leftNumber right: rightNumber top: topNumber bottom: bottomNumber
    ^self new origin: (Point x: leftNumber y: topNumber) corner: (Point x: rightNumber y: bottomNumber)
! !

! Rectangle methodsFor: 'accessing'!

origin: originPoint corner: cornerPoint
    origin <- originPoint.
    corner <- cornerPoint
!

origin
    ^origin
!

corner
    ^corner
!

topLeft
    ^origin
!

topCenter
    ^Point x: (origin x + (self width / 2)) y: (origin y)
!

topRight
    ^Point x: (corner x) y: (origin y)
!

rightCenter
    ^Point x: (corner x) y: (origin y + (self height / 2))
!

bottomCenter
    ^Point x: (origin x + (self width / 2)) y: (corner y)
!

bottomLeft
    ^Point x: (origin x) y: (corner y)
!

bottomRight
    ^corner
!

leftCenter
    ^Point x: (origin x) y: (origin y + (self height / 2))
!

center
    ^Point x: (origin x + (self width / 2))
	   y: (origin y + (self height / 2))
!

area
    ^ (self width) * (self height)
!

width
    ^(corner x) - (origin x)
!

height
    ^(corner y) - (origin y)
!

extent
    ^Point x: (self width) y: (self height)
!

top
    ^(origin y)
!

right
    ^(corner x)
!

bottom
    ^(corner y)
!

left
    ^(origin x)
! !

! Rectangle methodsFor: 'testing'!

"Not yet implemented: messages to set the locations as mentioned on p 346"
containsPoint: aPoint
    ^(origin <= aPoint) & (corner >= aPoint)
!

contains: aRectangle
    ^(self containsPoint: (aRectangle origin)) &
       (self containsPoint: (aRectangle corner))
!

intersects: aRectangle
    ^(self containsPoint: aRectangle topLeft) or:
       [(self containsPoint: aRectangle topRight) or:
           [(self containsPoint: aRectangle bottomLeft) or:
               [(self containsPoint: aRectangle bottomRight)]]]
!

= aRectangle
    ^(origin = aRectangle origin)
	and: [ corner = aRectangle corner ]
!

hash
    ^(origin hash) * (corner hash)
! !

! Rectangle methodsFor: 'rectangle functions'!

amountToTranslateWithin: aRectangle
    ^(aRectangle origin)-origin
!

"----------------------------------------------------------------
|areasOutside: aRectangle
| most complicated of the Rectangle primitives
| The basic methodology is to first determine that there is an
| intersection by finding the overlapping rectangle.  From the
| overlapping rectangle, first determine if it runs along an edge.
| If it doesn't, extend the rectangle up to the top edge and add
| the new rectangle to the collection and start the rest of the
| process.  If the left edge does not touch the left edge of self,
| extend it to the edge saving the new rectangle.  Then do the
| same to the right edge.  Then check top and bottom edges.  Most
| of the time only 2 or 3 rectangles get formed, occasionally 4.
| It should be possible to never get more than 3 but requires more
| work.
 ----------------------------------------------------------------"

areasOutside: aRectangle
    | collect iRect tmp |
    iRect <- self intersect: aRectangle.
    (iRect = nil) ifTrue: [^nil]. "case of no intersection"
                               "the collect collection gathers Rectangles"
    collect <- OrderedCollection new: 4.
                               "is it floating or on the edge?"
    (((iRect top) ~= self top) &
             ((iRect bottom) ~= self bottom) &
                   ((iRect left) ~= self left) & ((iRect right) ~= self right))
       ifTrue: "entirely in the center."
           [tmp <- Rectangle origin: (Point x: iRect left y: self top)
                            corner: iRect bottomRight.
            collect add: tmp.
            iRect <- iRect merge: tmp].
    ((iRect left) ~= self left)
       ifTrue:                 "doesn't touch left edge so make it touch"
           [tmp <- Rectangle origin: (Point x: self left y: iRect top)
                                corner: iRect bottomLeft.
                collect add: tmp.
                               "merge new (tmp) with overlap to keep track"
                iRect <- iRect merge: tmp].
    ((iRect right) ~= self right)
       ifTrue:                 "doesn't touch right edge so extendi it"
           [tmp <- Rectangle origin: iRect topRight
                                corner: (Point x: self right y: iRect bottom).
                collect add: tmp.
                iRect <- iRect merge: tmp].
    (((iRect left) ~= self left) | ((iRect top) ~= self top))
       ifTrue:                 "whole top part can be taken now"
           [tmp <- Rectangle origin: origin corner: iRect topRight.
                collect add: tmp].
    (((iRect right) ~= self right) | ((iRect bottom) ~= self bottom))
       ifTrue:                 "whole bottom open and can be taken"
           [tmp <- Rectangle origin: iRect bottomLeft corner: corner.
                collect add: tmp].
    ^collect
!

expandBy: delta
    (delta isMemberOf: Point) ifTrue:
       [^Rectangle origin: (origin-delta)
                   corner: (corner+delta)].
    (delta isMemberOf: Rectangle) ifTrue:
       [^Rectangle origin: (origin-(delta origin))
                   corner: (corner+(delta corner))].
    (delta isKindOf: Number) ifTrue:
       [^Rectangle left: (origin x)-delta
                   right:(corner x)+delta
                   top:  (origin y)-delta
                   bottom:(corner y)+delta].
    self error: 'Illegal delta value'
!

insetBy: delta
    (delta isMemberOf: Point) ifTrue:
       [^Rectangle origin: (origin+delta)
                   corner: (corner-delta)].
    (delta isMemberOf: Rectangle) ifTrue:
       [^Rectangle origin: (origin+(delta origin))
                   corner: (corner-(delta corner))].
    (delta isKindOf: Number) ifTrue:
       [^Rectangle left: (origin x)+delta
                   right:(corner x)-delta
                   top:  (origin y)+delta
                   bottom:(corner y)-delta].
    self error: 'Illegal delta value'
!

insetOriginBy: originDeltaPoint corner: cornerDeltaPoint
    ^Rectangle origin: origin + originDeltaPoint
              corner: corner + cornerDeltaPoint
!

merge: aRectangle
    | orig corn |
    orig <- Point x: ((origin x) min: (aRectangle origin x))
                y: ((origin y) min: (aRectangle origin y)).
    corn <- Point x: ((corner x) max: (aRectangle corner x))
                y: ((corner y) max: (aRectangle corner y)).
    ^Rectangle origin: orig corner: corn
!

"--------------------------------------------------------------
| A intersect: B
|   returns the rectangle (if any) created by the overlap of
|   rectangles A and B.  There are 10 possible overlap situations:
|      A inside B
|      B inside A
|      A overlaps B at one of the four corners (1 point inside)
|      A overlaps B on one of the four sides (2 points inside)
 ---------------------------------------------------------------"

intersect: aRectangle
    (self contains: aRectangle) ifTrue: [^Rectangle origin: aRectangle origin
                                                   corner: aRectangle corner].
    (aRectangle contains: self)  ifTrue: [^Rectangle origin: origin
                                                    corner: corner].
    (self containsPoint: aRectangle topLeft)
       ifTrue: [ (self containsPoint: aRectangle topRight)
                     ifTrue: [^Rectangle origin: aRectangle origin
                                         corner: (Point x: aRectangle corner x
                                                       y: corner y)]
                     ifFalse: [^Rectangle origin: aRectangle origin
                                          corner: corner]].
    (self containsPoint: aRectangle topRight)
       ifTrue: [^Rectangle origin: (Point x: origin x y: aRectangle origin y)
                           corner: (Point x: aRectangle corner x y: corner y)].
    (self containsPoint: aRectangle bottomLeft)
       ifTrue: [ (self containsPoint: aRectangle bottomRight)
                     ifTrue: [^Rectangle origin: (Point x: aRectangle origin x
                                                        y: origin y)
                                         corner: aRectangle corner]
                     ifFalse: [^Rectangle origin: (Point x: aRectangle origin x
                                                         y: origin y)
                                          corner: aRectangle corner]].
    (self containsPoint: aRectangle bottomRight)
       ifTrue: [^Rectangle origin: origin corner: aRectangle corner]
       ifFalse: [^nil]
! !

! Rectangle methodsFor: 'printing'!

printOn: aStream
    aStream print: origin;
	nextPutAll: ' corner: ';
	print: corner
!

storeOn: aStream
    aStream nextPutAll: '(Rectangle origin: ';
	store: origin;
	nextPutAll: ' corner: ';
	store: corner;
	nextPut: $)
! !

! Rectangle methodsFor: 'truncation and round off'!

rounded
    ^Rectangle origin: origin rounded corner: corner rounded
! !

! Rectangle methodsFor: 'transforming'!

moveBy: aPoint
    origin <- origin + aPoint.
    corner <- corner + aPoint
!

moveTo: aPoint
    | diff |
    diff <- aPoint - origin.
    origin <- aPoint.
    corner <- corner + diff
!

scaleBy: scale
    ^Rectangle origin: origin * scale corner: corner * scale
!

translateBy: factor
    ^Rectangle origin: origin + factor corner: corner + factor
! !

! Point methodsFor: 'converting'!

corner: aPoint
    ^Rectangle origin: self corner: aPoint
!

extent: aPoint
    ^Rectangle origin: self extent: aPoint
! !

Object subclass: 'BitBlt'
  instanceVariableNames:
    'destForm sourceForm halftoneForm combinationRule destX destY width height clipX clipY clipWidth clipHeight sourceX sourceY'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

! BitBlt class methodsFor: 'instance creation' !

destForm: destination sourceForm: source halftoneForm: halftone
        combinationRule: rule destOrigin: destOrigin
        sourceOrigin: sourceOrigin extent: extent clipRect: clipRect
            "Answer a BitBlt with values set according to
            each of the arguments, where rule is an Integer;
            destination, source, and halftone are Forms;
            destOrigin, sourceOrigin, and extent are Points;
            and clipRect is a Rectangle."
    ^self new destForm: destination sourceForm: source halftoneForm: halftone
        combinationRule: rule destOrigin: destOrigin
        sourceOrigin: sourceOrigin extent: extent clipRect: clipRect;
	yourself
! !

! BitBlt methodsFor: 'initialising' !

destForm: destination sourceForm: source halftoneForm: halftone
        combinationRule: rule destOrigin: destOrigin
        sourceOrigin: sourceOrigin extent: extent clipRect: clipRect
    destForm <- destination.
    sourceForm <- source.
    halftoneForm <- halftone.
    combinationRule <- rule.
    destX <- destOrigin x.
    destY <- destOrigin y.
    width <- extent x.
    height <- extent y.
    clipX <- clipRect left.
    clipY <- clipRect top.
    clipWidth <- clipRect width.
    clipHeight <- clipRect height.
    sourceX <- sourceOrigin x.
    sourceY <- sourceOrigin y
! !

! BitBlt methodsFor: 'accessing'!

sourceForm: aForm
            "Set the receiver's source form to be the
            argument, aForm."
    sourceForm <- aForm
!

destForm: aForm
            "Set the receiver's destination form to be the
            argument, aForm."
    destForm <- aForm
!

mask: aForm
            "Set the receiver's halftone mask form to be
            the argument, aForm."
    halftoneForm <- aForm
!

combinationRule: anInteger
            "Set the receiver's combination rule to be the
            argument, anInteger, which must be an integer
            between 0 and 15."
    combinationRule <- anInteger
!

clipHeight: anInteger
            "Set the receiver's clipping area height to be
            the argument, anInteger."
    clipHeight <- anInteger
!

clipWidth: anInteger
            "Set the receiver's clipping area width to be
            the argument, anInteger."
    clipWidth <- anInteger
!

clipRect
            "Answer the receiver's clipping rectangle."
    ^clipX @ clipY extent: clipWidth @ clipHeight
!

clipRect: aRectangle
            "Set the receiver's clipping rectangle to be
            the argument, aRectangle."
    clipX <- aRectangle left.
    clipY <- aRectangle top.
    clipWidth <- aRectangle width.
    clipHeight <- aRectangle height
!

clipX: anInteger
            "Set the receiver's clipping rectangle top left x
            coordinate to be the argument, anInteger."
    clipX <- anInteger
!

clipY: anInteger
            "Set the receiver's clipping rectangle top left y
            coordinate to be the argument, anInteger."
    clipY <- anInteger
!

sourceRect: aRectangle
            "Set the receiver's source form rectangular
            area to be the argument, anInteger."
    "Is this the Right Thing to do?"
    sourceX <- aRectangle left.
    sourceY <- aRectangle top.
    width <- aRectangle width.
    height <- aRectangle height
!

sourceOrigin: aPoint
            "Set the receiver's source form top left coordi-
            nates to be the argument, aPoint."
    sourceX <- aPoint x.
    sourceY <- aPoint y
!

sourceX: anInteger
            "Set the receiver's source form top left x
            coordinate to be the argument, anInteger."
    sourceX <- anInteger
!

sourceY: anInteger
            "Set the receiver's source form top left y
            coordinate to be the argument, anInteger."
    sourceY <- anInteger
!

destRect: aRectangle
            "Set the receiver's destination form rectangular
            area to be the argument, aRectangle."
    destX <- aRectangle left.         "Is this correct?"
    destY <- aRectangle top.
    width <- aRectangle width.
    height <- aRectangle height
!

destOrigin: aPoint
            "Set the receiver's destination form top left
            coordinate to be the argument, aPoint."
    destX <- aPoint x.
    destY <- aPoint y
!

destX: anInteger
            "Set the receiver's destination form top left x
            coordinate to be the argument, anInteger."
    destX <- anInteger
!

destY: anInteger
            "Set the receiver's destination form top left y
            coordinate to be the argument, anInteger."
    destY <- anInteger
!

height: anInteger
            "Set the receiver's destination form height to
            be the argument, anInteger."
    height <- anInteger
!

width: anInteger
            "Set the receiver's destination form width to be
            the argument, anInteger."
    width <- anInteger
! !

! BitBlt methodsFor: 'copying'!

copyBits
    <primitive 134>
    ^self primitiveFailed
! !

! BitBlt methodsFor: 'line drawing'!

drawFrom: startPoint to: stopPoint
            "Draw a line whose end points are the arguments,
            startPoint and stopPoint.  The line is
            formed by displaying copies of the current
            source form according to the receiver's halftone
            mask and combination rule."
    | deltaX deltaY |
    self destOrigin: startPoint.
    deltaX <- stopPoint x - startPoint y.
    deltaY <- stopPoint y - startPoint y.
    ^self drawLoop: deltaX and: deltaY
!

drawLoop: deltaX and: deltaY
     <primitive 136>
    ^ self primitiveFailed
! !

Object subclass: 'DisplayObject'
  instanceVariableNames: 'width height offset'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

DisplayObject subclass: 'DisplayMedium'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

DisplayMedium subclass: 'Form'
  instanceVariableNames: 'bitmap'
  classVariableNames: 
    'BlackMask VeryDarkGrayMask DarkGrayMask GrayMask LightGrayMask VeryLightGrayMask WhiteMask'
  poolDictionaries: ''
  category: 'Graphics Kernel'
!

! DisplayObject methodsFor: 'accessing' !

width
                    "Answer the width of the receiver's bounding
                    box, a rectangle that represents the boundaries
                    of the receiver's image."
    ^width
!

height
                    "Answer the height of the receiver's bounding
                    box."
    ^height
!

extent
                    "Answer a Point representing the width and
                    height of the receiver's bounding box."
    ^width @ height
!

offset
                    "Answer a Point representing the amount by
                    which the receiver should be offset when it is
                    displayed or its position is tested."
    ^offset
!

offset: aPoint
                    "Set the receiver's offset."
    offset <- aPoint
!

rounded
                    "Set the receiver's offset to the nearest integral
                    amount."
    offset <- offset rounded
! !

! DisplayObject methodsFor: 'transforming' !

scaleBy: aPoint
                    "Scale the receiver's offset by aPoint."
    offset <- offset * aPoint
!

translateBy: aPoint
                    "Translate the receiver's offset by aPoint."
    offset <- offset + aPoint
!

align: alignmentPoint with: relativePoint
                    "Translate the receiver's offset such that
                    alignmentPoint aligns with relativePoint."
    "Is this the Right Thing to do?"
    offset <- offset + relativePoint - alignmentPoint
! !

! DisplayObject methodsFor: 'display box access' !

boundingBox
                    "Answer the rectangular area that represents
                    the boundaries of the receiver's space of
                    information."
    ^offset extent: width @ height
! !

! DisplayObject methodsFor: 'displaying' !

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                rule: ruleInteger
                mask: aForm
                    "Display the receiver at location aDisplayPoint
                    with rule, ruleInteger, and halftone mask,
                    aForm.  Information to be displayed must be
                    confined to the area that intersects with
                    clipRectangle."
    (BitBlt destForm: aDisplayMedium sourceForm: self halftoneForm: aForm
            combinationRule: ruleInteger destOrigin: aDisplayPoint + offset
	    sourceOrigin: 0@0 extent: width @ height clipRect: clipRectangle)
	copyBits
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                rule: ruleInteger
                    "As above with mask a black Form (nil)."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: clipRectangle rule: ruleInteger mask: nil
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                    "As above with rule `over'."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: clipRectangle rule: Form over mask: nil
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                    "As above with clipping rectangle the whole
                    of aDisplayMedium."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: aDisplayMedium boundingBox
	  rule: Form over mask: nil
!

displayOn: aDisplayMedium
                            "As above at point 0@0."
    self displayOn: aDisplayMedium at: 0@0
          clippingBox: aDisplayMedium boundingBox
	  rule: Form over mask: nil
!

displayAt: aDisplayPoint
                    "Display the receiver at location aDisplayPoint
                    with rule `over' or `storing'; halftone mask, a
                    black Form (nil); clipping rectangle the whole display
                    screen; onto the display screen (Display)."
    self displayOn: Display at: aDisplayPoint
          clippingBox: Display boundingBox
	  rule: Form over mask: nil
!

display
                    "Display the receiver at location 0@0."
    self displayOn: Display at: 0@0
          clippingBox: Display boundingBox
	  rule: Form over mask: nil
! !

! DisplayMedium methodsFor: 'colouring' !

black
                    "Change all of the receiver's area to black."
    self black: (0@0 extent: self extent)
!

black: aRectangle
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to black."
    self fill: aRectangle
         rule: Form over
	 mask: nil
!

white
                    "Change all of the receiver's area to white."
    self white: (0@0 extent: self extent)
!

white: aRectangle
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to white."
    self fill: aRectangle
         rule: Form over
	 mask: Form white
!

gray
                    "Change all of the receiver's area to gray."
    self gray: (0@0 extent: self extent)
!

gray: aRectangle
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to gray."
    self fill: aRectangle
         rule: Form over
	 mask: Form gray
!

veryLightGray
                    "Change all of the receiver's area to very light
                    gray."
    self veryLightGray: (0@0 extent: self extent)
!

veryLightGray: aRectangle
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to very light gray."
    self fill: aRectangle
         rule: Form over
	 mask: Form veryLightGray
!

lightGray
                    "Change all of the receiver's area to light gray."
    self lightGray: (0@0 extent: self extent)
!

lightGray: aRectangle
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to light gray."
    self fill: aRectangle
         rule: Form over
	 mask: Form lightGray
!

darkGray
                    "Change all of the receiver's area to dark gray."
    self darkGray: (0@0 extent: self extent)
!

darkGray: aRectangle
                    "Change the area of the receiver defined by the
                     argument, aRectangle, to dark gray."
    self fill: aRectangle
         rule: Form over
	 mask: Form darkGray
!

fill: aRectangle mask: aHalftoneForm
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to white, by filling it
                    with the 16x16-bit pattern, aHalftoneForm.
                    The combination rule for copying the mask to
                    the receiver is 3 (Form over)."
    self fill: aRectangle rule: Form over mask: aHalftoneForm
!

fill: aRectangle rule: anInteger mask: aHalftoneForm
                    "Change the area of the receiver defined by the
                    argument, aRectangle, to white, by filling it
                    with the 16x16-bit pattern, aHalftoneForm.
                    The combination rule for copying the mask to
                    the receiver is anInteger."
    (BitBlt destForm: self sourceForm: nil halftoneForm: aHalftoneForm
            combinationRule: anInteger destOrigin: aRectangle origin
	    sourceOrigin: 0@0 extent: aRectangle extent clipRect: aRectangle)
	copyBits
!

reverse: aRectangle mask: aHalftoneForm
                    "Change the area of the receiver defined by the
                    argument, aRectangle, so that, in only those
                    bits in which the mask, aHalftoneForm, is
                    black, white bits in the receiver become black
                    and black becom white."
    (BitBlt destForm: self sourceForm: nil halftoneForm: aHalftoneForm
            combinationRule: Form reverse destOrigin: aRectangle origin
	    sourceOrigin: aRectangle origin extent: aRectangle extent
	    clipRect: aRectangle)
	copyBits
!

reverse: aRectangle
                    "Change the area in the receiver defined by the
                    argument, aRectangle, so that white is black
                    and black is white.  The default mask is Form
                    black (we use nil which is equivalent)."
    self reverse: aRectangle mask: Form black
!

reverse
                    "Change all of the receiver's area so that white
                    is black and black is white."
    self reverse: self boundingBox mask: Form black
! !

! DisplayMedium methodsFor: 'bordering' !

border: aRectangle widthRectangle: insets mask: aHalftoneForm
                    "Color an outline around the area within the
                    receiver defined by the argument, aRectangle.
                    The color is determined by the mask,
                    aHalftoneForm.  The width of the outline is de-
                    termined by the Rectangle, insets, such that,
                    origin x is the width of the left side, origin y
                    is the width of the top side, corner x is the
                    width of the right side, and corner y is the
                    width of the bottom side."
    | leftWidth topWidth rightWidth bottomWidth originX originY
      cornerX cornerY rectWidth rectHeight |
    leftWidth <- insets left.
    topWidth <- insets top.
    rightWidth <- insets right.
    bottomWidth <- insets bottom.
    originX <- aRectangle origin x.
    originY <- aRectangle origin y.
    cornerX <- aRectangle corner x.
    cornerY <- aRectangle corner y.
    rectWidth <- aRectangle width.
    rectHeight <- aRectangle height.
    self fill: (aRectangle origin extent: rectWidth @ topWidth)
         mask: aHalftoneForm.
    self fill: (originX @ (cornerY - bottomWidth)
                  extent: rectWidth @ bottomWidth)
         mask: aHalftoneForm.
    self fill: (originX @ (originY + topWidth)
                  extent: leftWidth @ (rectHeight - topWidth - bottomWidth))
         mask: aHalftoneForm.
    self fill: ((cornerX - rightWidth) @ (originY + topWidth)
                  extent: rightWidth @ (rectHeight - topWidth - bottomWidth))
         mask: aHalftoneForm
!

border: aRectangle width: borderWidth mask: aHalftoneForm
                    "Color an outline around the area within the
		    receiver defined by the argument, aRectangle.
                    The color is determined by the mask,
                    aHalftoneForm.  The width of all the sides is
                    borderWidth."
    self border: aRectangle
          widthRectangle: (borderWidth@borderWidth
	                         corner: borderWidth@borderWidth)
	  mask: aHalftoneForm
!

border: aRectangle width: borderWidth
                    "Color an outline around the area within the
                    receiver defined by the argument, aRectangle.
                    The color is Form black(nil).  The width of all the
                    sides is borderWidth."
    self border: aRectangle width: borderWidth mask: Form black
! !

! Form class methodsFor: 'instance creation' !

fromDisplay: aRectangle
                    "Answer a new Form whose bits are copied
                    from the display screen within the boundaries
                    defined by the argument, aRectangle, into the
                    receiver's bitmap."
    ^self new fromDisplay: aRectangle; yourself
!

extent: aPoint fromArray: anArray offset: offsetPoint
    ^self new extent: aPoint fromArray: anArray offset: offsetPoint;
              yourself
!

extent: extentPoint
    ^self new extent: extentPoint; white; yourself
!

fromString: aString
    ^self new fromString: aString; yourself
! !

! Form class methodsFor: 'creating standard masks' !

initialize
    BlackMask <- Form extent: 32@32
                   fromArray: #(16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
		                16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
			        16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
		                16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
			        16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
		                16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
			        16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF
			        16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF 16rFFFFFFFF)
		      offset: 0@0.
    VeryDarkGrayMask <- Form extent: 32@32
                   fromArray: #(16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
		                16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
				16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
		                16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
				16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
		                16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
				16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF
				16rDDDDDDDD 16rFFFFFFFF 16r77777777 16rFFFFFFFF)
			     offset: 0@0.
    DarkGrayMask <- Form extent: 32@32
                   fromArray: #(16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
			        16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
				16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
			        16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
				16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
			        16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
				16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD
				16r77777777 16rDDDDDDDD 16r77777777 16rDDDDDDDD)
			 offset: 0@0.
    GrayMask <- Form extent: 32@32
                  fromArray: #(16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555
			       16rAAAAAAAA 16r55555555 16rAAAAAAAA 16r55555555)
		     offset: 0@0.
    LightGrayMask <- Form extent: 32@32
                  fromArray: #(16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222
			       16r88888888 16r22222222 16r88888888 16r22222222)
			  offset: 0@0.
    VeryLightGrayMask <- Form extent: 32@32
                   fromArray: #(16r22222222 16r0 16r88888888 16r0
			        16r22222222 16r0 16r88888888 16r0
				16r22222222 16r0 16r88888888 16r0
			        16r22222222 16r0 16r88888888 16r0
				16r22222222 16r0 16r88888888 16r0
			        16r22222222 16r0 16r88888888 16r0
				16r22222222 16r0 16r88888888 16r0
				16r22222222 16r0 16r88888888 16r0)
			      offset: 0@0.
    WhiteMask <- Form extent: 32@32
                      fromArray: #(16r0 16r0 16r0 16r0
		                   16r0 16r0 16r0 16r0
				   16r0 16r0 16r0 16r0
		                   16r0 16r0 16r0 16r0
				   16r0 16r0 16r0 16r0
		                   16r0 16r0 16r0 16r0
				   16r0 16r0 16r0 16r0
				   16r0 16r0 16r0 16r0)
		      offset: 0@0
! !

! Form class methodsFor: 'mask constants' !

black
                    "Answer the Form denoting a black mask."
    ^BlackMask
!

veryDarkGray
                    "Answer the Form denoting a dark gray mask."
    ^VeryDarkGrayMask
!

darkGray
                    "Answer the Form denoting a dark gray mask."
    ^DarkGrayMask
!

gray
                    "Answer the Form denoting a gray mask."
    ^GrayMask
!

lightGray
                    "Answer the Form denoting a light gray mask."
    ^LightGrayMask
!

veryLightGray
                    "Answer the Form denoting a very light gray
                    mask."
    ^VeryLightGrayMask
!

white
                    "Answer the Form denoting a white mask."
    ^WhiteMask
! !


! Form class methodsFor: 'mode constants' !
   "Mode constants will be index into the array
           #(Clear And AndReverse Copy AndInverted
	     NoOp Xor Or Nor Equiv Invert
	     OrReverse CopyInverted OrInverted
	     Nand Set)
    of the mode required - 1 since modes are in the range 0 - 15"

erase
                    "Answer the Integer denoting mode erase."
    ^0  "Clear"
!

and
                    "Answer the Integer denoting mode and."
    ^1  "And"
!

over
                    "Answer the Integer denoting mode over."
    ^3  "Copy"
!

reverse
                    "Answer the Integer denoting mode reverse."
    ^6  "Xor"
!

under
                    "Answer the Integer denoting mode under."
    ^7  "Or"
!

set
    ^15  "Set - not defined in the Blue Book, but I need it."
! !

! Form methodsFor: 'initialise-release' !

fromDisplay: aRectangle
                    "Copy the bits from the display screen within
                    the boundaries defined by the argument,
                    aRectangle, into the receiver's bitmap."
    self extent: aRectangle extent offset: 0@0.
    (BitBlt destForm: self sourceForm: Display halftoneForm: nil
            combinationRule: Form over destOrigin: 0@0
	    sourceOrigin: aRectangle origin extent: aRectangle extent
	    clipRect: (0@0 extent: aRectangle extent))
	copyBits
!

extent: aPoint fromArray: anArray offset: offsetPoint
    "Can only create Forms of width 16 with this method
     at the moment."
    width <- aPoint x.
    height <- aPoint y.
    offset <- offsetPoint.
    bitmap <- WordArray new: ((width // 32 ) * height).
    1 to: anArray size do: [ :i | bitmap at: i put: (anArray at: i) ].
!

fromString: aString
    "bitmap <- Bitmap fromString: aString.
    width <- bitmap width.
    height <- bitmap height.
    offset <- 0@0"
! !

! Form methodsFor: 'accessing' !

extent: aPoint
                    "Set the width and height of the receiver to be
                    the coordinates of the argument, aPoint."
    width <- aPoint x.
    height <- aPoint y.
    offset <- 0@0.
    bitmap <- WordArray new: ((width // 32 ) * height).
!

extent: extentPoint offset: offsetPoint
                    "Set the width and height of the receiver to be
                    the coordinates of the argument, extentPoint,
                    and the offset to be offsetPoint."
    self extent: extentPoint.
    offset <- offsetPoint
!

bitmap
    ^bitmap
! !

! Form methodsFor: 'copying' !

copyFrom: sourceForm halftone: halftoneForm
         rule: combinationRule srcX: sourceX srcY: sourceY
	 area: copyArea
     (BitBlt destForm: self sourceForm: sourceForm 
	halftoneForm: halftoneForm combinationRule: combinationRule
	destOrigin: 0@0 sourceOrigin: (sourceX @ sourceY) extent: 0@0 
	clipRect: copyArea) copybits.
!

drawFrom: startPoint to: stopPoint rule: combinationRule
     (BitBlt destForm: Display sourceForm: self 
	halftoneForm: nil combinationRule: combinationRule
	destOrigin: 0@0 sourceOrigin: 0@0 extent: 0@0 
	clipRect: nil) drawFrom: startPoint to: stopPoint.
! !

! Form methodsFor: 'pattern' !

valueAt: aPoint
                    "Answer the bit, 0 or 1, at location aPoint within
                    the receiver's bitmap."
    <primitive 138>
    ^ self primitiveFailed
!

valueAt: aPoint put: bitCode
                    "Set the bit at location aPoint within the receiver's
                    bitmap to be bitCode, either 0 or 1."
    <primitive 139>
    ^ self primitiveFailed
! !

! Form methodsFor: 'displaying text' !

displayString: aString at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: mask
    bitmap isNil
        ifTrue: [ ^nil ].
    bitmap displayString: aString at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: mask
! !

! Form methodsFor: 'display managment' !

beDisplay
	<primitive 130>
	^ self primitiveFailed
! !

Form initialize !

Object subclass: 'InputSensor'
  instanceVariableNames:
    'mousePoint currentCursor keyboardQueue button1Pressed button2Pressed button3Pressed'
  classVariableNames: 'InSemaphore'
  poolDictionaries: ''
  category: ''Graphic-Kernel' !

! InputSensor class methodsFor: 'initialising' !

initialize
    ^ self new initialize.
! !

! InputSensor methodsFor: 'private' !

resize
   " For right now nothing, will be replaced later "
    ^ self
!

getInput
    <primitive 129>
    ^ self primitiveFailed
!

setSemaphore: aSemaphore
    <primitive 128>
   ^ self primitiveFailed
! !

! InputSensor methodsFor: 'initializing' !

initialize
    | map |
    InSemaphore <- Semaphore new.
    self setSemaphore: InSemaphore.
    Smalltalk at: #Sensor put: self.
    self initKeyboardQueue.
    self startSensorLoop
! !

! InputSensor methodsFor: 'accessing' !

redButtonPressed
    ^button1Pressed
!

yellowButtonPressed
    ^button2Pressed
!

blueButtonPressed
    ^button3Pressed
!

anyButtonPressed
    ^(button1Pressed
        or: [ button2Pressed
	          or: [ button3Pressed ] ])
!

noButtonPressed
    ^(button1Pressed not
        and: [ button2Pressed not
	           and: [ button3Pressed not ] ])
!

keyboard
    ^keyboardQueue next
!

keyboardPressed
    ^keyboardQueue isEmpty not
!

keyboardPeek
    ^keyboardQueue peek
!

flushKeyboard
    self initKeyboardQueue
!

mousePoint
    ^mousePoint
!

cursorPoint
    currentCursor isNil
        ifTrue: [ ^mousePoint ]
	ifFalse: [ ^mousePoint + currentCursor offset ]
!

waitButton
    [ self noButtonPressed ]
          whileTrue: [ ]
!

waitNoButton
    [ self anyButtonPressed ]
          whileTrue: [ ]
!

waitClickButton
    self waitButton.
    self waitNoButton 
!

currentCursor
    ^currentCursor
!

currentCursor: aCursor
    currentCursor <- aCursor 
    currentCursor beCursor.
!

startSensorLoop
    | event value x y |
    [ [ true ] whileTrue: [
	InSemaphore wait.
	event <- self getInput.
	value <- event // 16.
	event <- event bitAnd: 16rF.

	event == 0 ifTrue: [ "Timer event " ].
	event == 1 ifTrue: [ "Char event"
		keyboardQueue nextPut: value.
	].
	event == 2 ifTrue: [ "Mouse Pointer event" 
		x <- value bitAnd: 16rFFF.
		y <- (value bitShift: -12) bitAnd; 16rFFF.
		mousePoint <- x@y.
	].
	event == 3 ifTrue: [ "Mouse Button event"
		((value bitAnd: 1) == 1) ifTrue: [ button1Pressed <- true ]
				        ifFalse: [ button1Pressed <- false ].
		((value bitAnd: 2) == 2) ifTrue: [ button2Pressed <- true ]
				        ifFalse: [ button2Pressed <- false ].
		((value bitAnd: 4) == 4) ifTrue: [ button3Pressed <- true ]
				        ifFalse: [ button3Pressed <- false ].
        ].
	event == 4 ifTrue: [ "Resize event"
		self resize.
	]
     ] forkAt: Processor lowIOPriority.
!

initKeyboardQueue
    keyboardQueue <- SharedQueue new.
    button1Pressed <- false.
    button2Pressed <- false.
    button3Pressed <- false.
    mousePoint <- 0@0
! !

