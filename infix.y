%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

#define DEBUG /* for debuging: print production results */
int lineNum = 1;

/* prototype functions */
struct nodeVar* assignVar(char *name, int val);
struct nodeVar* findVar(char *name, int val, struct nodeVar *var);
struct nodeVar* newVar(char* name, int val);
void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

struct nodeVar *head;

%}

%code requires {
	struct nodeVar
	{
		char varName[20];
		int val;
		struct nodeVar *next;
	} nodeVar;
}

%union {
	char name[20];
	int d;
	struct nodeVar *nPtr;
}

// need to choose token type from union above
%token <d> NUMBER
%token <name> TEXT
%token QUIT
%right '='
%token '(' ')'
%left '+' '-'
%left '*' '/'
%right POW
%right '!'
%type <d> exp factor term
%right '\n'
%start infix

%%
infix : exp QUIT
	{ 
		printf("=%d\nQuiting ...\n", $1);
		return $1;
	}
	| QUIT
	{
		printf("Quiting ...\n");
		return 0;
	}

exp : exp '+' factor
	{ 
		$$ = $1 + $3;
		#ifdef DEBUG
		printf("exp %d <- exp %d + factor %d\n", $$, $1, $3);
		#endif
	}
	| exp '-' factor
	{ 
		$$ = $1 - $3;
		#ifdef DEBUG
		printf("exp %d <- exp %d - factor %d\n", $$, $1, $3);
		#endif
	}
    | factor
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("exp %d <- factor %d\n", $$, $1);
		#endif
	}
	| exp '\n'
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("exp %d <- exp %d \\n\n", $$, $1);
		#endif
		printf("=%d\n", $1);
	}
	| '!' term
	{
		$$ = ($2 == 0) ? 1 : 0;
		#ifdef DEBUG
		printf("exp %d <- ! %d\n", $$, $2);
		#endif
	}
	| exp '!' term
	{
		$$ = ($3 == 0) ? 1 : 0;
		#ifdef DEBUG
		printf("exp %d <- exp ! %d\n", $$, $3);
		#endif
	}
	| TEXT
	{

	}
	| TEXT '=' exp
	{
		$$ = assignVar($1, $3)->val;
		#ifdef DEBUG
		printf("exp %d <- text %s = exp %d\n", $$, $1, $3);
		#endif
	}
	| exp TEXT '=' exp
	{
		$$ = assignVar($2, $4)->val;
		#ifdef DEBUG
		printf("exp %d <- exp text %s = exp %d\n", $$, $2, $4);
		#endif
	};

factor : factor '*' term
	{ 
		$$ = $1 * $3; 
		#ifdef DEBUG
		printf("factor %d <- factor %d * term %d\n", $$, $1, $3);
		#endif
	}
	| factor '/' term
	{ 
		$$ = $1 / $3; 
		#ifdef DEBUG
		printf("factor %d <- factor %d / term %d\n", $$, $1, $3);
		#endif
	}
	| factor POW term
	{
		$$ = 1;
		for (int i=0; i<$3; i++)
		{
			$$ *= $1; 
		}
		#ifdef DEBUG
		printf("factor %d <- factor %d ** term %d\n", $$, $1, $3);
		#endif
	}
	| term
	{
		$$ = $1;
		#ifdef DEBUG
		printf("factor %d <- term %d\n", $$, $1);
		#endif
	};

term : NUMBER
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("term %d <- number %d\n", $$, $1);
		#endif
	}
	| exp NUMBER
		{ 
		$$ = $2;
		#ifdef DEBUG
		printf("term %d <- exp number %d\n", $$, $2);
		#endif
	}
	| '(' exp ')'
	{
		$$ = $2;
		#ifdef DEBUG
		printf("term %d <- (exp) %d\n", $$, $2);
		#endif
	};

%%

struct nodeVar* assignVar(char *name, int val)
{
	struct nodeVar *var = findVar(name, val, head);
	return var;
}

struct nodeVar* findVar(char *name, int val, struct nodeVar *var)
{
	if(strcmp(name, var->varName) != 0)
	{
		return var;
	}
	else if (var->next == NULL)
	{
		var->next = newVar(name, val);
		return var->next;
	}
	else
	{
		return findVar(name, val, var->next);
	}
	
}

struct nodeVar* newVar(char* name, int val)
{
	struct nodeVar* var = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	sscanf(name, "%s", var->varName);
	var->val = val;
	var->next = NULL;
	return var; 
}

int main() {
	head = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	yyparse();
	return 0;
}
