
/*
 * Smalltalk interpreter: Lexiconal Scanner.
 *
 * $Id: $
 *
 * $Log: $
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
    int                 pushptr;
    char                push[10];
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

