
/*
 * Smalltalk interpreter: Lexiconal Scanner.
 *
 * $Log: lex.c,v $
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: lex.c,v 1.1 1999/09/02 15:57:59 rich Exp rich $";

#endif

/* System stuff */
#ifdef unix
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>
#include <math.h>
#include <memory.h>
#endif
#ifdef _WIN32
#include <stddef.h>
#include <windows.h>
#include <math.h>

#define malloc(x)	GlobalAlloc(GMEM_FIXED, x)
#define free(x)		GlobalFree(x)
#endif

#include "object.h"
#include "smallobjs.h"
#include "primitive.h"
#include "lex.h"
#include "fileio.h"
#include "dump.h"

#define ALLOCSIZE	16

char               *specs = "+/\\*~<>=@%|&?!";

struct arraylst {
    Objptr              op;
    struct arraylst    *next;
};

static char         nextchar(Token);
static void         pushback(Token, char);
static char         peekchar(Token);
static int          isSpecial(char);
static void         skipcomment(Token);
static int          isLetter(char);
static int          isNumber(char);
static int          scanarray(Token);
static int          scannumber(Token, char);
static int          scanname(Token);
static int          scanstring(Token);
static int          scanliteral(Token);

/*
 * Create a new scanner object.
 */
Token
new_tokscanner(char *str)
{
    Token               tstate;

    if (str == NULL)
	return NULL;
    if ((tstate = (Token) malloc(sizeof(token))) == NULL) {
	free(str);
	return NULL;
    }
    tstate->buffer = tstate->str = str;
    tstate->pushback = -1;
    tstate->spec[0] = '\0';
    tstate->string = NULL;
    tstate->object = NilPtr;
    return tstate;
}

/*
 * Remove the scanner object.
 */
void
done_scan(Token tstate)
{
    if (tstate->string != NULL)
	free(tstate->string);
    free(tstate);
}

/*
 * Return next character from input stream.
 */

static char
nextchar(Token tstate)
{
    if (tstate->pushback != -1) {
	char c = tstate->pushback;
	tstate->pushback = -1;
	return c;
    }

    if (*tstate->str == '\0')
	return '\0';

    return *tstate->str++;
}

/*
 * Put character back to be reread.
 */
static void
pushback(Token tstate, char c)
{
    if (tstate->pushback != -1)
	parseError(tstate, "Push back exceeded", NULL);
    tstate->pushback = c;
}

/*
 * Peek at the next character.
 */
static char
peekchar(Token tstate)
{
    if (tstate->pushback != -1)
    	return tstate->pushback;
    return *tstate->str;
}

/*
 * Print out a compile error. Dump definition up to last parsed char.
 */
void
parseError(Token tstate, char *msg, char *value)
{
    char	       *ptr, *solptr, *wptr, *optr;
    char		buffer[1024];

    ptr = tstate->str;
    if (tstate->pushback != 0)
	ptr--;
    optr = buffer;
    /* Dump method up till error */
    for(solptr = wptr = tstate->buffer; wptr != ptr && *wptr != '\0'; wptr++) {
	if (*wptr == '\r' || *wptr == '\n') {
	    *optr++ = '\0';
	    if (*buffer != '\0')
	        dump_string(buffer);
	    optr = buffer;
	    solptr = ptr;
	} else {
	    *optr++ = *wptr;
	}
    }

    /* Dump rest of line out */
    ptr = optr;
    for(;*wptr != '\0'; wptr++) {
	if (*wptr == '\r' || *wptr == '\n') {
	    *optr++ = '\0';
	    if (*buffer != '\0')
	        dump_string(buffer);
	    optr = buffer;
	    break;
	} else {
	    *optr++ = *wptr;
	}
    }

    /* Now clean out buffer */
    for(wptr = buffer; wptr != ptr; wptr++) {
	if (*wptr != '\t')
	   *wptr = ' ';
    }

    *wptr++ = '^';
    while (*msg != '\0')
	*wptr++ = *msg++;

    if (value != NULL)
	while(*value != '\0')
	    *wptr++ = *value++;

    *wptr++ = '\0';
    error(buffer);
}


     
/*
 * Check if character is a special char.
 */
static int
isSpecial(char c)
{
    char               *ptr;

    for (ptr = specs; *ptr != '\0'; ptr++)
	if (*ptr == c)
	    return TRUE;
    return FALSE;
}

/*
 * Skip over comments.
 */
static void
skipcomment(Token tstate)
{
    char                c;

    while ((c = nextchar(tstate)) != '\0')
	if (c == '"')
	    if (peekchar(tstate) != '"')
		break;
}

/*
 * Return true if character is a letter.
 */
static int
isLetter(char c)
{
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'))
	return TRUE;
    else
	return FALSE;
}

/*
 * Return true if character is a number.
 */
static int
isNumber(char c)
{
    if (c >= '0' && c <= '9')
	return TRUE;
    else
	return FALSE;
}

/*
 * Scan an array definition.
 */
static int
scanarray(Token tstate)
{
    char                c;
    struct arraylst    *lst = NULL, *newel;
    int                 sz = 0;
    Objptr              op;

    for (; (c = nextchar(tstate)) != '\0';) {
	switch (c) {
	case '"':
	    skipcomment(tstate);
	case ' ':
	case '\t':
	case '\r':
	case '\n':
	    continue;
	case '(':
	    if (!scanarray(tstate))
		goto done;
	    break;
	case ')':

	   /* Convert into a array object */
	    op = create_new_object(ArrayClass, sz);
	    for (newel = lst; newel != NULL;) {
		Set_object(op, --sz, newel->op);
		lst = newel->next;
		free(newel);
		newel = lst;
	    }
	    tstate->object = op;
	    return TRUE;

	case '-':
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	    scannumber(tstate, c);
	    break;

	case 'a':
	case 'b':
	case 'c':
	case 'd':
	case 'e':
	case 'f':
	case 'g':
	case 'h':
	case 'i':
	case 'j':
	case 'k':
	case 'l':
	case 'm':
	case 'n':
	case 'o':
	case 'p':
	case 'q':
	case 'r':
	case 's':
	case 't':
	case 'u':
	case 'v':
	case 'w':
	case 'x':
	case 'y':
	case 'z':
	case 'A':
	case 'B':
	case 'C':
	case 'D':
	case 'E':
	case 'F':
	case 'G':
	case 'H':
	case 'I':
	case 'J':
	case 'K':
	case 'L':
	case 'M':
	case 'N':
	case 'O':
	case 'P':
	case 'Q':
	case 'R':
	case 'S':
	case 'T':
	case 'U':
	case 'V':
	case 'W':
	case 'X':
	case 'Y':
	case 'Z':
	    pushback(tstate, c);
	case '#':
	    scanliteral(tstate);
	    break;

	case '$':
	    c = nextchar(tstate);
	    tstate->object = get_pointer(CharacterTable, c
			+ (fixed_size(CharacterTable) / sizeof(Objptr)));
	    break;

	case '\'':
	    scanstring(tstate);
	    break;

	default:
	    goto done;
	}

	if ((newel = (struct arraylst *) malloc(sizeof(struct arraylst))) == NULL)
	                        break;

	newel->op = tstate->object;
	newel->next = lst;
	lst = newel;
	sz++;

    }
  done:
   /* Free the array */
    for (newel = lst; newel != NULL;) {
	lst = newel->next;
	free(newel);
	newel = lst;
    }
    return FALSE;
}

/*
 * Scan a number and return it as an object.
 */
static int
scannumber(Token tstate, char c)
{
    int                 base = 10;
    int                 baseseen = FALSE;
    int			eseen = FALSE;
    int			fseen = FALSE;
    int                 value;
    int                 integer = 0;
    double              fraction = 0.0;
    int                 sign = 1;
    int                 exp = 0;

    if (c == '-') {
	sign = -1;
	c = nextchar(tstate);
    }
   /* Scan first part of number. */
  redo:
    while (isNumber(c) || (c >= 'A' && c <= 'Z')) {
	if (isNumber(c))
	    value = c - '0';
	else
	    value = 10 + (c - 'A');
	if (value > base)
	    break;
	integer = (integer * base) + value;
	c = nextchar(tstate);
    }

   /* Check if radix value */
    if (c == 'r') {
	base = integer;
	integer = 0;
	if (baseseen)
	    return FALSE;
	c = nextchar(tstate);
	baseseen = TRUE;
	goto redo;
    }

   /* Check if fractional value */
    if (c == '.') {
	double              multi = 1.0 / ((double) base);

	c = peekchar(tstate);
	if (!isNumber(c) && (c < 'A' || c > 'Z')) {
	    c = '.';
	} else {
	    c = nextchar(tstate);
	    fseen = TRUE;
	    while (isNumber(c) || (c >= 'A' && c <= 'Z')) {
	        if (isNumber(c))
		    value = c - '0';
	        else
		    value = 10 + (c - 'A');
	        if (value > base)
		    break;
	        fraction += value * multi;
	        multi /= (double) base;
	        c = nextchar(tstate);
	    }
	}
    }

   /* Check if exponent */
    if (c == 'e') {
	int                 esign = 1;

	c = nextchar(tstate);
	if (c == '-') {
	    esign = -1;
	    c = nextchar(tstate);
	} else if (c == '+')
	    c = nextchar(tstate);

	while (isNumber(c)) {
	    exp = (exp * 10) + (c - '0');
	    c = nextchar(tstate);
	}

	eseen = TRUE;
	exp *= esign;
    } 

   /* We read one char to many, put it back */
    pushback(tstate, c);

   /* Got a number now convert it to a object */
    if (fseen || eseen) {
	double             *fval;

       /* Floating point value */
	tstate->object = create_new_object(FloatClass, sizeof(double));

	fval = (double *) get_object_base(tstate->object);
	*fval = ((double) sign) * (((double)integer) + fraction);
	if (eseen)
	    *fval = pow(*fval, (double) exp);
    } else {
	integer *= sign;
	tstate->object = as_integer_object(integer);
    }
    return TRUE;
}

/*
 * Scan a name and return it in string.
 */
static int
scanname(Token tstate)
{
    char               *buf, *ptr;
    int                 size, left;
    char                c;

    if (tstate->string != NULL) {
	free(tstate->string);
	tstate->string = NULL;
    }

    if (!isLetter(peekchar(tstate)))
	return FALSE;

   /* Space for trailing zero and a : */
    if ((buf = (char *) malloc(ALLOCSIZE + 2)) == NULL)
	return FALSE;
    left = ALLOCSIZE;
    ptr = buf;
    size = ALLOCSIZE;
    while (isLetter(c = nextchar(tstate)) || isNumber(c)) {
	if (left == 0) {
	    if ((buf = (char *) realloc(buf, size + ALLOCSIZE + 2)) == NULL)
		return FALSE;
	    ptr = &buf[size];
	    size += ALLOCSIZE;
	    left = ALLOCSIZE;
	}
	*ptr++ = c;
	left--;
    }
    pushback(tstate, c);
    *ptr++ = '\0';
    tstate->string = buf;
    return TRUE;
}

/*
 * Scan a string and return a string object.
 */
static int
scanstring(Token tstate)
{
    char               *buf, *ptr;
    int                 size, left;
    char                c;

   /* Space for trailing zero  */
    if ((buf = (char *) malloc(ALLOCSIZE + 1)) == NULL)
	return FALSE;
    left = ALLOCSIZE;
    ptr = buf;
    size = ALLOCSIZE;
    do {
	c = nextchar(tstate);
	if (c == '\'') {
	    if (peekchar(tstate) != '\'')
		break;
	    else
		(void) nextchar(tstate);
	}
	if (left == 0) {
	    if ((buf = (char *) realloc(buf, size + ALLOCSIZE + 1)) == NULL)
		return FALSE;
	    ptr = &buf[size];
	    size += ALLOCSIZE;
	    left = ALLOCSIZE;
	}
	*ptr++ = c;
	left--;
    } while (c != '\0');
    if (c == '\0')
	return FALSE;
    *ptr++ = '\0';
    tstate->object = MakeString(buf);
    free(buf);
    return TRUE;
}

/*
 * Scan a literal, either a array or a symbol.
 */
static int
scanliteral(Token tstate)
{
    char                c;

    c = peekchar(tstate);

    if (c == '(') {
       /* Scan an array */
	(void)nextchar(tstate);
	scanarray(tstate);
    } else if (isLetter(c)) {
	char               *buf, *ptr;
	int                 size, left;

       /* Space for trailing zero and a : */
	if ((buf = (char *) malloc(ALLOCSIZE + 1)) == NULL)
	    return FALSE;
	left = ALLOCSIZE;
	ptr = buf;
	size = ALLOCSIZE;
	while (isLetter(c = nextchar(tstate)) || isNumber(c) || c == ':') {
	    if (left == 0) {
		if ((buf = (char *) realloc(buf,
					  size + ALLOCSIZE + 1)) == NULL)
		    return FALSE;
		ptr = &buf[size];
		size += ALLOCSIZE;
		left = ALLOCSIZE;
	    }
	    *ptr++ = c;
	    left--;
	}
	pushback(tstate, c);
	*ptr++ = '\0';
	tstate->object = internString(buf);
	free(buf);
    } else if (c == '-') {
	tstate->spec[0] = nextchar(tstate);
	tstate->spec[1] = '\0';
	tstate->object = internString(tstate->spec);
    } else if (isSpecial(c)) {
	tstate->spec[0] = nextchar(tstate);
	if (isSpecial(peekchar(tstate))) {
	    tstate->spec[1] = nextchar(tstate);
	    tstate->spec[2] = '\0';
	} else
	    tstate->spec[1] = '\0';
	tstate->object = internString(tstate->spec);
    }
    return TRUE;
}

/*
 * Return the next token from input stream.
 */
int
get_token(Token tstate)
{
    char                c;
    int                 tok;

    while ((c = nextchar(tstate)) != '\0') {
	switch (c) {
	   /* Skip over leading blanks */
	case ' ':
	case '\t':
	case '\r':
	case '\n':
	    tok = -1;
	    break;
	case '"':
	    skipcomment(tstate);
	    tok = -1;
	    break;
	case '(':
	    tok = KeyRParen;
	    break;
	case ')':
	    tok = KeyLParen;
	    break;
	case ';':
	    tok = KeyCascade;
	    break;
	case '.':
	    tok = KeyPeriod;
	    break;
	case '^':
	    tok = KeyReturn;
	    break;
	case ']':
	    tok = KeyRBrack;
	    break;
	case '[':
	    tok = KeyLBrack;
	    break;

	case '<':
	    tstate->spec[0] = c;
	    c = tstate->spec[1] = nextchar(tstate);
	    tstate->spec[2] = '\0';
            tok = KeySpecial;
	    if (c == '-') {
		tok = KeyAssign;
	    } else if (!isSpecial(c)) {
		pushback(tstate, c);
		tstate->spec[1] = '\0';
	    }
	    break;
	case '-':
	    if (isNumber(peekchar(tstate))) {
		scannumber(tstate, '-');
		tok = KeyLiteral;
		break;
	    } 
	    /* Fall through */

	case '+':
	case '/':
	case '\\':
	case '*':
	case '~':
	case '>':
	case '=':
	case '@':
	case '%':
	case '?':
	case '!':
	case '&':
	case '|':
        case ',':
	    tstate->spec[0] = c;
	    if (isSpecial(peekchar(tstate))) {
		tstate->spec[1] = nextchar(tstate);
		tstate->spec[2] = '\0';
	    } else
		tstate->spec[1] = '\0';
	    tok = KeySpecial;
	    break;

	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	    scannumber(tstate, c);
	    tok = KeyLiteral;
	    break;
	case '#':
	    scanliteral(tstate);
	    tok = KeyLiteral;
	    break;

	case '$':
	    c = nextchar(tstate);
	    tstate->object = get_pointer(CharacterTable, c
			+ (fixed_size(CharacterTable) / sizeof(Objptr)));
	    tok = KeyLiteral;
	    break;

	case ':':
	    if (scanname(tstate))
		tok = KeyVariable;
	    else {
		pushback(tstate, c);
		tstate->spec[0] = ':';
		tstate->spec[1] = '\0';
		tok = KeyUnknown;
	    }
	    break;
	case '\'':
	    if (scanstring(tstate))
	        tok = KeyLiteral;
	    else
	        tok = KeyUnknown;
	    break;

	case 'a':
	case 'b':
	case 'c':
	case 'd':
	case 'e':
	case 'f':
	case 'g':
	case 'h':
	case 'i':
	case 'j':
	case 'k':
	case 'l':
	case 'm':
	case 'n':
	case 'o':
	case 'p':
	case 'q':
	case 'r':
	case 's':
	case 't':
	case 'u':
	case 'v':
	case 'w':
	case 'x':
	case 'y':
	case 'z':
	case 'A':
	case 'B':
	case 'C':
	case 'D':
	case 'E':
	case 'F':
	case 'G':
	case 'H':
	case 'I':
	case 'J':
	case 'K':
	case 'L':
	case 'M':
	case 'N':
	case 'O':
	case 'P':
	case 'Q':
	case 'R':
	case 'S':
	case 'T':
	case 'U':
	case 'V':
	case 'W':
	case 'X':
	case 'Y':
	case 'Z':
	    pushback(tstate, c);
 	    tok = KeyName;
	    if (scanname(tstate)) {
		if (peekchar(tstate) == ':') {
		    (void) nextchar(tstate);
		    strcat(tstate->string, ":");
		    tok = KeyKeyword;
		}
	    }
	    break;
	default:
	    tstate->spec[0] = c;
	    tstate->spec[1] = '\0';
	    tok = KeyUnknown;
	    break;
	}
	if (tok != -1) {
	    tstate->tok = tok;
	    if (tok != KeyEOS)
		return tok;
	}
    }
    tstate->tok = KeyEOS;
    return KeyEOS;
}
