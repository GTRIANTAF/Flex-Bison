%{
#include "myhtml.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}
%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z]
STRING      \"[^\"]*\"|\'[^\']*\'
POS_INT     [1-9]{DIGIT}*|0
WHITESPACE  [ \t\n\r]+
IDENTIFIER  [a-zA-Z][a-zA-Z0-9_-]*

%x COMMENT
%x IN_TAG

%%

"<!--"              { printf("DEBUG: COMMENT_OPEN at line %d\n", yylineno); BEGIN(COMMENT); return COMMENT_OPEN; }
<COMMENT>"-->"      { printf("DEBUG: COMMENT_CLOSE at line %d\n", yylineno); BEGIN(INITIAL); return COMMENT_CLOSE; }
<COMMENT>"--"       { fprintf(stderr, "Error at line %d: invalid '--' inside comment\n", yylineno); }
<COMMENT>[^-]+      { printf("DEBUG: COMMENT_TEXT at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return COMMENT_TEXT; }
<COMMENT>"-"        { printf("DEBUG: COMMENT_TEXT at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return COMMENT_TEXT; }

"<MYHTML>"          { printf("DEBUG: MYHTML_OPEN at line %d\n", yylineno); return MYHTML_OPEN; }
"</MYHTML>"         { printf("DEBUG: MYHTML_CLOSE at line %d\n", yylineno); return MYHTML_CLOSE; }
"<head>"            { printf("DEBUG: HEAD_OPEN at line %d\n", yylineno); return HEAD_OPEN; }
"</head>"           { printf("DEBUG: HEAD_CLOSE at line %d\n", yylineno); return HEAD_CLOSE; }
"<meta"             { printf("DEBUG: META_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return META_OPEN; }
"<title>"           { printf("DEBUG: TITLE_OPEN at line %d\n", yylineno); return TITLE_OPEN; }
"</title>"          { printf("DEBUG: TITLE_CLOSE at line %d\n", yylineno); return TITLE_CLOSE; }
"<body>"            { printf("DEBUG: BODY_OPEN at line %d\n", yylineno); return BODY_OPEN; }
"</body>"           { printf("DEBUG: BODY_CLOSE at line %d\n", yylineno); return BODY_CLOSE; }
"<a"                { printf("DEBUG: A_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return A_OPEN; }
"</a>"              { printf("DEBUG: A_CLOSE at line %d\n", yylineno); return A_CLOSE; }
"<p"                { printf("DEBUG: P_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return P_OPEN; }
"</p>"              { printf("DEBUG: P_CLOSE at line %d\n", yylineno); return P_CLOSE; }
"<img"              { printf("DEBUG: IMG_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return IMG_OPEN; }
"<form"             { printf("DEBUG: FORM_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return FORM_OPEN; }
"</form>"           { printf("DEBUG: FORM_CLOSE at line %d\n", yylineno); return FORM_CLOSE; }
"<input"            { printf("DEBUG: INPUT_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return INPUT_OPEN; }
"<label"            { printf("DEBUG: LABEL_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return LABEL_OPEN; }
"</label>"          { printf("DEBUG: LABEL_CLOSE at line %d\n", yylineno); return LABEL_CLOSE; }
"<div"              { printf("DEBUG: DIV_OPEN at line %d\n", yylineno); BEGIN(IN_TAG); return DIV_OPEN; }
"</div>"            { printf("DEBUG: DIV_CLOSE at line %d\n", yylineno); return DIV_CLOSE; }

<IN_TAG>"id"{WHITESPACE}*"="               { printf("DEBUG: ID_ATTR at line %d\n", yylineno); return ID_ATTR; }
<IN_TAG>"charset"{WHITESPACE}*"="          { printf("DEBUG: CHARSET_ATTR at line %d\n", yylineno); return CHARSET_ATTR; }
<IN_TAG>"name"{WHITESPACE}*"="             { printf("DEBUG: NAME_ATTR at line %d\n", yylineno); return NAME_ATTR; }
<IN_TAG>"style"{WHITESPACE}*"="            { printf("DEBUG: STYLE_ATTR at line %d\n", yylineno); return STYLE_ATTR; }
<IN_TAG>"content"{WHITESPACE}*"="          { printf("DEBUG: CONTENT_ATTR at line %d\n", yylineno); return CONTENT_ATTR; }
<IN_TAG>"href"{WHITESPACE}*"="             { printf("DEBUG: HREF_ATTR at line %d\n", yylineno); return HREF_ATTR; }
<IN_TAG>"src"{WHITESPACE}*"="              { printf("DEBUG: SRC_ATTR at line %d\n", yylineno); return SRC_ATTR; }
<IN_TAG>"alt"{WHITESPACE}*"="              { printf("DEBUG: ALT_ATTR at line %d\n", yylineno); return ALT_ATTR; }
<IN_TAG>"width"{WHITESPACE}*"="            { printf("DEBUG: WIDTH_ATTR at line %d\n", yylineno); return WIDTH_ATTR; }
<IN_TAG>"height"{WHITESPACE}*"="           { printf("DEBUG: HEIGHT_ATTR at line %d\n", yylineno); return HEIGHT_ATTR; }
<IN_TAG>"for"{WHITESPACE}*"="              { printf("DEBUG: FOR_ATTR at line %d\n", yylineno); return FOR_ATTR; }
<IN_TAG>"type"{WHITESPACE}*"="             { printf("DEBUG: TYPE_ATTR at line %d\n", yylineno); return TYPE_ATTR; }
<IN_TAG>"value"{WHITESPACE}*"="            { printf("DEBUG: VALUE_ATTR at line %d\n", yylineno); return VALUE_ATTR; }

<IN_TAG>"/>"                { printf("DEBUG: SELF_CLOSE at line %d\n", yylineno); BEGIN(INITIAL); return SELF_CLOSE; }
<IN_TAG>">"                 { printf("DEBUG: > at line %d\n", yylineno); BEGIN(INITIAL); return '>'; }

<IN_TAG>{WHITESPACE}        { /* skip whitespace */ }
<IN_TAG>{STRING}            { printf("DEBUG: STRING at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return STRING; }
<IN_TAG>{IDENTIFIER}        { printf("DEBUG: IDENTIFIER at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return TEXT; }

{WHITESPACE}        { /* skip whitespace */ }
{STRING}            { printf("DEBUG: STRING at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return STRING; }
{POS_INT}           { printf("DEBUG: POS_INT at line %d: %s\n", yylineno, yytext); yylval.num = atoi(yytext); return POS_INT; }

[^<>]+              { printf("DEBUG: TEXT at line %d: '%s'\n", yylineno, yytext); yylval.str = strdup(yytext); return TEXT; }

.                   { printf("DEBUG: CHAR at line %d: '%c' (ASCII %d)\n", yylineno, yytext[0], yytext[0]); return yytext[0]; }
%%