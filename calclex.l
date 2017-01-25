/*
*This is the definition section of a lex file. 
*All functions prototypes and variable declarations go within %{%}. 
*These will be inserted verbatim at the top of the generated C file. 
*The various sections in a lex file are definition, rules and finally the subroutines section.
*Each section is seperated by a %% sign.
*/
%{
#include <stdlib.h>
#include "CalcIncl.h"
#include "y.tab.h"

void yyerror(char *);
%}
%%
 /*This is the rules section.
  *This section is used to specify the patterns that will be matched by the lexical analyzer.
  *Patterns are specified using regular expressions and must always be written starting first character of a line.
  *Each pattern can have a meaning action associated with it which is seperated from the pattern by a whitespace
  *Meaning of different variables in a lex program:
  *yytext: This denotes the string that is matched by the regular expression
  *yylval: This denotes the value of the matched token
  *The tokens VARIABLE, INTEGER used in the lex file are defined as token in the yacc file
  *The variables in this simple language can only contain one character and are stored in a symbol table along with their values*/
[a-z] { yylval.sIndex = *yytext - 'a';
		return VARIABLE;
	  } 
0 { yylval.iValue = atoi(yytext); 
		return INTEGER;
	  }
[1-9][0-9]* {yylval.iValue = atoi(yytext); return INTEGER;}
[-+*/()<>=;{}.] {return *yytext;}

">=" return GE;
"<=" return LE;
"==" return EQ;
"!=" return NE;
"while" return WHILE;
"if" return IF;
"else" return ELSE;
"print" return PRINT;

[ \t\n] ; /*Ignore Whitespace*/
. yyerror("Unknown Character!");
%%

int yywrap(void) {
	return 1;
}
