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
		char varName[100];
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
%type <d> exp factor term statement
%right '\n'
%start infix

%%
infix : exp '\n'
	{ 
		printf("=%d\n", $1);
	}
	| statement '\n'
	{
		printf("=%d\n", $1);
	}
	| infix exp '\n'
	{ 
		printf("=%d\n", $2);
	}
	| infix statement '\n'
	{
		printf("=%d\n", $2);
	}
	| infix '\n'
	{
		#ifdef DEBUG
		printf("Blank '\\n' found\n");
		#endif
	};
	
statement : TEXT '=' exp
{
	struct nodeVar *node = assignVar($1, $3);
	$$ = $3;
	#ifdef DEBUG
	printf("variable %s is = %d\n", $1, $3);
	#endif
}
| TEXT
{
	struct nodeVar *node = findVar($1, 0, head);
	$$ = node->val;
	#ifdef DEBUG
	printf("variable %s is %d\n", $1, node->val);
	#endif
};


exp : exp '+' factor
	{ 
		$$ = $1 + $3;
		#ifdef DEBUG
		printf("exp %d : exp %d + factor %d\n", $$, $1, $3);
		#endif
	}
	| exp '-' factor
	{ 
		$$ = $1 - $3;
		#ifdef DEBUG
		printf("exp %d : exp %d - factor %d\n", $$, $1, $3);
		#endif
	}
    | factor
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("exp %d : factor %d\n", $$, $1);
		#endif
	}
	| statement '+' factor
	{
		$$ = $1 + $3;
		#ifdef DEBUG
		printf("exp %d : statement %d + factor %d\n", $$, $1, $3);
		#endif
	}
	;

factor : factor '*' term
	{ 
		$$ = $1 * $3; 
		#ifdef DEBUG
		printf("factor %d : factor %d * term %d\n", $$, $1, $3);
		#endif
	}
	| factor '/' term
	{ 
		$$ = $1 / $3; 
		#ifdef DEBUG
		printf("factor %d : factor %d / term %d\n", $$, $1, $3);
		#endif
	}
       | term
	{
		$$ = $1;
		#ifdef DEBUG
		printf("factor %d : term %d\n", $$, $1);
		#endif
	}
	;

term : NUMBER
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("term %d : number %d\n", $$, $1);
		#endif
	}
     | '(' exp ')'
	{
		$$ = $2;
		#ifdef DEBUG
		printf("term %d : (exp) %d\n", $$, $2);
		#endif
	}
	;

%%

struct nodeVar* assignVar(char *name, int val)
{
	struct nodeVar *var = findVar(name, val, head);
	var->val = val;
	return var;
}

struct nodeVar* findVar(char *name, int val, struct nodeVar *var)
{
	if(strcmp(name, var->varName) == 0)
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

void freeNodes()
{
	#ifdef DEBUG
	printf("Freeing all variable Nodes\n");
	#endif
	struct nodeVar *node = head->next;
	while(node != NULL)
	{
		struct nodeVar *tmp = node->next;
		free(node);
		node = tmp;
	}

	return;
}

int main() {
	head = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	yyparse();
	freeNodes();
	return 0;
}
