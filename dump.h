/*
 * Smalltalk interpreter: Object Dumper.
 *
 * $Id: $
 *
 * $Log: $
 *
 */

void                dump_otable();
void                dump_object(int);
void                dump_objects();
void		    dump_method(Objptr);
void                dump_token(int, void *);
void		    trace_inst(Objptr, int, int, int, Objptr, int);
void		    dump_send(Objptr, Objptr, Objptr);
void		    dump_str(char *, Objptr);
