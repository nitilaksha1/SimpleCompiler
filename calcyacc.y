%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "CalcIncl.h"

/*Function prototype*/
nodeType *opr (int opr, int nops, ...);
nodeType *id (int i);
nodeType *con (int value);
int ex (nodeType *);
extern FILE *yyin;

void freeNode (nodeType *);
void yyerror (char *s);
int yylex();
int sym[26];	/*symbol table for storing variable names*/
static int lbl;
%}
/*The union type of YYSTYPE which is the actual type of yylval*/
%union {
	int iValue;
	char sIndex;
	nodeType *nPtr;
};
/*Binding Integer to ivalue. Required for yacc to generate correct code*/
%token <iValue> INTEGER
%token <sIndex> VARIABLE
%token WHILE IF PRINT
%nonassoc IFX
%nonassoc ELSE

/*Left associativity is specified in a rather simple manner avoiding making changes in the grammar*/
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
/*Specifies that unary minus has no associativity*/
%nonassoc UMINUS
/*Required for some reason not yet known*/
%type <nPtr> stmt expr stmt_list
%%
/** Yacc works using two stacks:
	* Parse Stack
	* Value Stack
*The tokens are pushed on the parse stack and the values associated with the tokens are pushed on the value stack.
*At any point the parse and value stacks are always synchronized in that we can always find the corresponding value of a token in the value stack.
*The usage of the parse stack is as follows:
	* The input token sent by the lexer is initially pushed on the stack and a shift operation is performed to move to next character in input stream.
	* Further operations that would occur can only be either a shift or a reduce operation.
	* A shift operation moves the input pointer to next character.
	* A reduce operation matches the values on the parse stack with a non terminal production on rhs of production.
	* If matched it pops the tokens ffrom the parse stack and pushes the non terminal on the lhs of the matching production.
	* If yacc is unsure whether a shift or a reduce operation should occur it is called a shift reduce conflict.
	* The default behaviour of yacc in a shift reduce conflict is to perform a shift operation.
	* The decision to peform a shift or reduce decides the precedence and associativity of operators
*/

/*RULES SECTION OF A YACC FILE:
* In this section below the syntax of the language is defined using BNF grammar.
* It is specified in terms of productions and each production
* The symbols $$,$1,$2 acutally have some meaning:
	* $$ represents the value at the top of the value stack. This usually has the value after a reduce operation has a been performed.
	* $1 represents the first non terminal on the RHS of a production and $2 is likewise.
*/
program: 
	   function {exit(0);}
	   ;

function:
		function stmt {ex($2); freeNode($2);}
		|
		;

stmt:
	          ';'                            { $$ = opr(';', 2, NULL, NULL); }
        | expr ';'                       { $$ = $1; }
        | PRINT expr ';'                 { $$ = opr(PRINT, 1, $2); }
        | VARIABLE '=' expr ';'          { $$ = opr('=', 2, id($1), $3); }
        | WHILE '(' expr ')' stmt        { $$ = opr(WHILE, 2, $3, $5); }
        | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5); }
        | IF '(' expr ')' stmt ELSE stmt { $$ = opr(IF, 3, $3, $5, $7); }
        | '{' stmt_list '}'              { $$ = $2; }
        ;

stmt_list:
		           stmt                  { $$ = $1; }
        | stmt_list stmt        { $$ = opr(';', 2, $1, $2); }
        ;

expr:
	          INTEGER               { $$ = con($1); }
        | VARIABLE              { $$ = id($1); }
        | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
        | expr '+' expr         { $$ = opr('+', 2, $1, $3); }
        | expr '-' expr         { $$ = opr('-', 2, $1, $3); }
        | expr '*' expr         { $$ = opr('*', 2, $1, $3); }
        | expr '/' expr         { $$ = opr('/', 2, $1, $3); }
        | expr '<' expr         { $$ = opr('<', 2, $1, $3); }
        | expr '>' expr         { $$ = opr('>', 2, $1, $3); }
        | expr GE expr          { $$ = opr(GE, 2, $1, $3); }
        | expr LE expr          { $$ = opr(LE, 2, $1, $3); }
        | expr NE expr          { $$ = opr(NE, 2, $1, $3); }
        | expr EQ expr          { $$ = opr(EQ, 2, $1, $3); }
        | '(' expr ')'          { $$ = $2; }
        ;

%%


nodeType *con(int value) {
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeCon;
    p->con.value = value;

    return p;
}

nodeType *id(int i) {
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeId;
    p->id.idval = i;

    return p;
}

nodeType *opr(int oper, int nops, ...) {
    va_list ap;
    nodeType *p;
    int i;

    /* allocate node, extending op array */
    if ((p = malloc(sizeof(nodeType) + (nops-1) * sizeof(nodeType *))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for (i = 0; i < nops; i++)
        p->opr.op[i] = va_arg(ap, nodeType*);
    va_end(ap);
    return p;
}

void freeNode(nodeType *p) {
    int i;

    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++)
            freeNode(p->opr.op[i]);
    }
    free (p);
}

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int ex(nodeType *p) {
	int lbl1, lbl2;

	if (!p) return 0;

	switch(p->type) {
		case typeCon:       
			printf("\tpush\t%d\n", p->con.value); 
			break;

		case typeId:        
			printf("\tpush\t%c\n", p->id.idval + 'a'); 
			break;

		case typeOpr:
			switch(p->opr.oper) {
				case WHILE:
					printf("L%03d:\n", lbl1 = lbl++);
					ex(p->opr.op[0]);
					printf("\tjz\tL%03d\n", lbl2 = lbl++);
					ex(p->opr.op[1]);
					printf("\tjmp\tL%03d\n", lbl1);
					printf("L%03d:\n", lbl2);
					break;

				case IF:
					ex(p->opr.op[0]);
					if (p->opr.nops > 2) {
						/* if else */
						printf("\tjz\tL%03d\n", lbl1 = lbl++);
						ex(p->opr.op[1]);
						printf("\tjmp\tL%03d\n", lbl2 = lbl++);
						printf("L%03d:\n", lbl1);
						ex(p->opr.op[2]);
						printf("L%03d:\n", lbl2);																																} else {
																																																																																			printf("\tjz\tL%03d\n", lbl1 = lbl++);
																																												    ex(p->opr.op[1]);
																																													printf("L%03d:\n", lbl1);
																																									            }
					  break;

				case PRINT:     
					ex(p->opr.op[0]);
					printf("\tprint\n");
					break;
														          
				case '=':       
														     
		   			ex(p->opr.op[1]);
							
					printf("\tpop\t%c\n", p->opr.op[0]->id.idval + 'a');

					break;

				case UMINUS:    

					ex(p->opr.op[0]);


					printf("\tneg\n");

					break;

				default:

					ex(p->opr.op[0]);
	
					ex(p->opr.op[1]);

					switch(p->opr.oper) {

						case '+':   printf("\tadd\n"); break;

						case '-':   printf("\tsub\n"); break; 

						case '*':   printf("\tmul\n"); break;

						case '/':   printf("\tdiv\n"); break;

						case '<':   printf("\tcompLT\n"); break;

						case '>':   printf("\tcompGT\n"); break;

						case GE:    printf("\tcompGE\n"); break;

						case LE:    printf("\tcompLE\n"); break;

						case NE:    printf("\tcompNE\n"); break;

						case EQ:    printf("\tcompEQ\n"); break;

					}

			}
	}
	
	return 0;
}	

int main(int argc, char **argv) {
	yyin = fopen(argv[1], "r");
    yyparse();
	fclose(yyin);
    return 0;
}
