Font subclass: 'TextStyle'
       instanceVariableNames: 'justify alignment firstIndent restIndent spacing'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Graphic-Kernel' !

! TextStyle class methodsFor: 'creation' !

new
    ^ super new initialize ; yourself
! !

! TextSytle methodsFor: 'access' !

name: aName
	name <- aName.
!

name: aName size: aSize
	name <- aName.
	size <- aSize
!

size: aSize
	size <- aSize
!

spacing: aOffset
	spacing <- aOffset.
!

alignment: aSymbol
	alignment <- aSymbol.
!

spacing 
	^ spacing
!

firstIndent 
	^ firstIndent
!

hangIndent 
	^ restIndent
!

alignment
	^ alignment
!

= aTextStyle
	(aTextStyle isBold and: bold) ifFalse: [ ^ false ].
	(aTextStyle isItalic and: italic) ifFalse: [ ^ false ].
	(aTextStyle isUnderline and: underline) ifFalse: [ ^ false ].
	(aTextStyle isStrikeout and: strikeout) ifFalse: [ ^ false ].
	aTextStyle name = name ifFalse: [ ^ false ].
	aTextStyle size = size ifFalse: [ ^ false ].
	aTextStyle spacing = spacing ifFalse: [ ^ false ].
	aTextStyle aligment = aligment ifFalse: [ ^ false ].
	aTextStyle firstIndent = firstIndent ifFalse: [ ^ false ].
	aTextStyle restIndent = restIndent ifFalse: [ ^ false ].
	^ true
!

normal
	super normal.
	firstIndent <- 0.
	restIndent <- 0.
	spacing <- 1.
	alignment <- #Fill
! !

! TextStyle methodsFor: 'emphasis' !

addEmphasis: aEmphasis
	| cn k v |
	cn <- aEmphasis class.
	" If new style is textstyle, merge "
 	cn == self class ifTrue: [
		aEmphasis name isNil ifFalse: [ name <- aEmphasis name ].
		aEmphasis size isNil ifFalse: [ size <- aEmphasis size ].
		aEmphasis firstIndent == 0 ifFalse:
				 [ firstIndent <- aEmphasis firstIndent ].
		aEmphasis hangIndent == 0 ifFalse:
				 [ restIndent <- aEmphasis hangIndent ].
		aEmphasis spacing == 1 ifFalse:
				 [ spacing <- aEmphasis spacing ].
		aEmphasis alignment == #Fill ifFalse: 
				 [ alignment <- aEmphasis alignment ].
		aEmphasis isBold ifTrue: [ self bold ].
		aEmphasis isItalic ifTrue: [ self italic ].
		aEmphasis isUnderline ifTrue: [ self underline ].
		aEmphasis isStrikeout ifTrue: [ self strikeout ].
		^ self
	].
	" Associations are handled differently. "
        cn == Association ifTrue: [
		k <- aEmphasis key.
		v <- aEmphasis value.
		k == #Name ifTrue: [ name <- v ].
		k == #Size ifTrue: [ size <- v ].
		k == #Indent ifTrue: [ firstIndent <- v ].
		k == #HangIndent ifTrue: [ restIndent <- v ].
		k == #Spacing ifTrue: [ spacing <- v ].
		^ self.
   	].
	cn == Symbol ifTrue: [
	    (aEmphasis == #RightJustify or: [ (aEmphasis == #LeftJustify
	    or: [ (aEmphasis == #Center or: [ (aEmphasis == #Fill) ])])])
		ifTrue: [ alignment <- aEmphasis ]
	    	ifFalse: [ self addStyle: emphasis ]
	] ifFalse: [
	    aEmphasis do: [ :e | self addEmphasis: e ]]
	].
	^ self.
!

removeEmphasis: aEmphasis
	| cn k |
	cn <- aEmphasis class.
	" Associations are handled differently. "
        cn == Association ifTrue: [ aEmphasis <- aEmphasis key.
				    cn <- aEmphasis class ].
	" If new style is textstyle, remove settings "
 	cn == self class ifTrue: [
		aEmphasis name isNil ifFalse: [ name <- nil ].
		aEmphasis size isNil ifFalse: [ size <- nil ].
		aEmphasis firstIndent == 0 ifFalse: [ firstIndent <- 0 ].
		aEmphasis hangIndent == 0 ifFalse: [ restIndent <- 0 ].
		aEmphasis spacing == 1 ifFalse: [ spacing <- 1 ].
		aEmphasis alignment == #Fill ifFalse: [ alignment <- #Fill ].
		aEmphasis isBold ifTrue: [ self nobold ].
		aEmphasis isItalic ifTrue: [ self noitalic ].
		aEmphasis isUnderline ifTrue: [ self nounderline ].
		aEmphasis isStrikeout ifTrue: [ self nostrikeout ].
		^ self
	].
	# If symbol, remove item.
	cn == Symbol ifTrue: [
	    aEmphasis == #Indent ifTrue: [ firstIndent <- 0. ^ self ].
	    aEmphasis == #HangIndent ifTrue: [ restIndent <- 0. ^ self ].
	    aEmphasis == #Spacing ifTrue: [ spacing <- 1. ^ self  ].
	    aEmphasis == self alignment ifTrue: [ alignment <- #Fill. ^ self ].
	    aEmphasis == #Name ifTrue: [ name <- nil. ^ self ].
	    aEmphasis == #Size ifTrue: [ size <- nil. ^ self ].
	    ^ self removeStyle: aEmphasis.
	].
	aEmphasis isKindOf: Collection ifTrue: [
		 aEmphasis do: [ :e | self removeEmphasis: em ]].
	^ self.
!

includesEmphasis: aEmphasis
	| cn k |
	cn <- aEmphasis class.
	" If aEmphasis style is textstyle compare "
 	cn == self class ifTrue: [
	].
	(aEmphasis isKindOf: Collection) ifTrue: [
	    k <- true.
	    aEmphasis do: [ :e | 
		(self includesEmphasis: e) ifFalse: [ k <- false ]
	    ].
	    ^ k
	].
	cn == Symbol ifTrue: [
	    aEmphasis == #Indent ifTrue: [ ^ firstIndent ~= 0 ].
	    aEmphasis == #HangIndent ifTrue: [ ^ restIndent ~= 0 ].
	    aEmphasis == #Spacing ifTrue: [ ^ spacing ~= 1  ].
	    aEmphasis == self alignment ifTrue: [ ^ true ].
	    aEmphasis == #Name ifTrue: [ ^ name notNil ].
	    aEmphasis == #Size ifTrue: [ ^ size notNil ].
	    ^ self includesStyle: emphasis.
	].
	^ false
! !

