
/*
 * Smalltalk interpreter: Lexiconal Scanner.
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

