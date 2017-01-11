/*
 * Smalltalk interpreter: Lexiconal Scanner.
 *
 * Copyright 1999-2017 Richard P. Cornwell.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the the Artistic License (2.0). You may obtain a copy
 * of the full license at:
 *
 * http://www.perlfoundation.org/artistic_license_2_0
 *
 * Any use, modification, and distribution of the Standard or Modified
 * Versions is governed by this Artistic License. By using, modifying or
 * distributing the Package, you accept this license. Do not use, modify, or
 * distribute the Package, if you do not accept this license.
 *
 * If your Modified Version has been derived from a Modified Version made by
 * someone other than you, you are nevertheless required to ensure that your
 * Modified Version complies with the requirements of this license.
 *
 * This license does not grant you the right to use any trademark, service
 * mark, tradename, or logo of the Copyright Holder.
 *
 * Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
 * AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
 * YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
 * CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: lex.h,v 1.2 2000/02/01 18:09:54 rich Exp $
 *
 * $Log: lex.h,v $
 * Revision 1.2  2000/02/01 18:09:54  rich
 * Pushback now just single character.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#define KeyEOS		 0 
#define KeyLiteral	 1
#define KeyName		 2
#define KeyKeyword	 3
#define KeyAssign	 4
#define KeyRParen	 5
#define KeyLParen	 6
#define KeyReturn	 7
#define KeyCascade	 8
#define KeyPeriod	 9
#define KeySpecial	10
#define KeyRBrack	11
#define KeyLBrack	12
#define KeyVariable	13
#define	KeyUnknown	14

typedef struct _token {
    int                 tok;
    char               *buffer;
    char               *str;
    char                pushback;
    char               *string;
    Objptr              object;
    char                spec[4];
} token            , *Token;

Token               new_tokscanner(char *str);
int                 get_token(Token);
void                done_scan(Token);
void		    parseError(Token, char *, char *);

/*
 * Return state information about token.
 */
#define get_token_object(tstate)  ((tstate)->object)
#define get_token_string(tstate)  ((tstate)->string)
#define get_token_spec(tstate)  ((tstate)->spec)
#define get_cur_token(tstate) ((tstate)->tok)

