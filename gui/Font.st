Object subclass: 'Font'
       instanceVariableNames: 'name size bold italic underline strikeout'
       classVariableNames: 'FontFamilies SystemFont'
       poolDictionaries: ''
       category: 'Graphic-Kernel' !

! Font class methodsFor: 'access' !

systemFont
	^ self new systemFont
!

family: aName
	^ self new normal family: aName
!

family: aName size: aSize
	^ self new normal family: aName size: aSize
! !

! Font methodsFor: 'access' !

systemFont
	| font |
	font <- SystemFont.
	name <- font name.
	size <- font size.
	italic <- font italic.
	bold <- font bold.
!

family: aName
	name <- aName.
!

family: aName size: aSize
	name <- aName.
	size <- aSize
!

size: aSize
	size <- aSize
!

normal
	bold <- false.
	italic <- false.
        underline <- false.
	strikeout <- false.
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

underline
	underline <- true
!

nounderline 
	underline <- false
!

strikeout
	strikeout <- true
!

nostrikeout
	strikeout <- false
!

size
	^ size
!

name
	^ name
!

= aFont
	(aFont isBold and: bold) ifFalse: [ ^ false ].
	(aFont isItalic and: italic) ifFalse: [ ^ false ].
	(aFont isUnderline and: underline) ifFalse: [ ^ false ].
	(aFont isStrikeout and: strikeout) ifFalse: [ ^ false ].
	aFont name = name ifFalse: [ ^ false ].
	aFont size = size ifFalse: [ ^ false ].
	^ true
! !

style: aStyle
	aStyle == #Bold ifTrue: [ ^ self bold ].
	aStyle == #Italic ifTrue: [ ^ self italic ].
	aStyle == #BoldItalic ifTrue: [ ^ self bolditalic ].
	aStyle == #StrikeOut ifTrue: [ ^ self strikeout ].
	aStyle == #Underline ifTrue: [ ^ self underline ].
	^ self normal.
!
addStyle: aStyle
	aStyle == #Bold ifTrue: [ ^ self bold ].
	aStyle == #Italic ifTrue: [ ^ self italic ].
	aStyle == #BoldItalic ifTrue: [ ^ self bolditalic ].
	aStyle == #StrikeOut ifTrue: [ ^ self strikeout ].
	aStyle == #Underline ifTrue: [ ^ self underline ].
!

removeStyle: aStyle
	aStyle == #Bold ifTrue: [ ^ self nobold ].
	aStyle == #Italic ifTrue: [ ^ self noitalic ].
	aStyle == #BoldItalic ifTrue: [ self nobold. ^ self noitalic ].
	aStyle == #StrikeOut ifTrue: [ ^ self nostrikeout ].
	aStyle == #Underline ifTrue: [ ^ self nounderline ].
!

includesStyle: aStyle
	aStyle == #Bold ifTrue: [ ^ self isBold ].
	aStyle == #Italic ifTrue: [ ^ self isItalic ].
	aStyle == #BoldItalic ifTrue: [ ^ (self isItalic or: (self isBold)) ].
	aStyle == #StrikeOut ifTrue: [ ^ self isStrikeout ].
	aStyle == #Underline ifTrue: [ ^ self isUnderline ].
!

isItalic
	^ italic
!

isBold
	^ bold
!

isStrikeout
	^ strikeout
!

isUnderline
	^ underline
!

font
	| family fname fsize index font |
	" Find family with same name "
	name isNil ifTrue: [
	    " No name, use system font "
	    family <- SystemFont.
	] ifFalse: [
	    family <- FontFamilies at: name asSymbol ifAbsent: [ nil ].
	].
	" If we got one, see if we can find right size "
	family isNil ifFalse: [
	    " See if size can be found "
	    size isNil ifFalse: [
	       font <- family at: size ifAbsent: [ nil ]
  	    ].
	    " Still not got one, grab any font in family "
	    font isNil ifTrue: [ family do: [ :e | font <- e ] ]
	].
	" Still no font, use system font "
	font isNil ifTrue: [ font <- SystemFont ].
	index <- 1.
	italic ifTrue: [ index <- index + 1 ].
	bold ifTrue:  [ index <- index + 2 ].
	font <- font at: index.
	font isNil ifTrue: [ font <- SystemFont ].
	^ font 
! !

! Font methodsFor: 'private' !

setSystem
	SystemFont <- self font.
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

