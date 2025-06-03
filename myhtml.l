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

"<!--"              { BEGIN(COMMENT); return COMMENT_OPEN; }
<COMMENT>"-->"      { BEGIN(INITIAL); return COMMENT_CLOSE; }
<COMMENT>"--"       { fprintf(stderr, "Error at line %d: invalid '--' inside comment\n", yylineno); }
<COMMENT>[^-]+      { yylval.str = strdup(yytext); return COMMENT_TEXT; }
<COMMENT>"-"        { yylval.str = strdup(yytext); return COMMENT_TEXT; }

"<MYHTML>"          { return MYHTML_OPEN; }
"</MYHTML>"         { return MYHTML_CLOSE; }
"<head>"            { return HEAD_OPEN; }
"</head>"           { return HEAD_CLOSE; }
"<meta"             { BEGIN(IN_TAG); return META_OPEN; }
"<title>"           { return TITLE_OPEN; }
"</title>"          { return TITLE_CLOSE; }
"<body>"            { return BODY_OPEN; }
"</body>"           { return BODY_CLOSE; }
"<a"                { BEGIN(IN_TAG); return A_OPEN; }
"</a>"              { return A_CLOSE; }
"<p"                { BEGIN(IN_TAG); return P_OPEN; }
"</p>"              { return P_CLOSE; }
"<img"              { BEGIN(IN_TAG); return IMG_OPEN; }
"<form"             { BEGIN(IN_TAG); return FORM_OPEN; }
"</form>"           { return FORM_CLOSE; }
"<input"            { BEGIN(IN_TAG); return INPUT_OPEN; }
"<label"            { BEGIN(IN_TAG); return LABEL_OPEN; }
"</label>"          { return LABEL_CLOSE; }
"<div"              { BEGIN(IN_TAG); return DIV_OPEN; }
"</div>"            { return DIV_CLOSE; }

<IN_TAG>"id"{WHITESPACE}*"="               { return ID_ATTR; }
<IN_TAG>"charset"{WHITESPACE}*"="          { return CHARSET_ATTR; }
<IN_TAG>"name"{WHITESPACE}*"="             { return NAME_ATTR; }
<IN_TAG>"style"{WHITESPACE}*"="            { return STYLE_ATTR; }
<IN_TAG>"content"{WHITESPACE}*"="          { return CONTENT_ATTR; }
<IN_TAG>"href"{WHITESPACE}*"="             { return HREF_ATTR; }
<IN_TAG>"src"{WHITESPACE}*"="              { return SRC_ATTR; }
<IN_TAG>"alt"{WHITESPACE}*"="              { return ALT_ATTR; }
<IN_TAG>"width"{WHITESPACE}*"="            { return WIDTH_ATTR; }
<IN_TAG>"height"{WHITESPACE}*"="           { return HEIGHT_ATTR; }
<IN_TAG>"for"{WHITESPACE}*"="              { return FOR_ATTR; }
<IN_TAG>"type"{WHITESPACE}*"="             { return TYPE_ATTR; }
<IN_TAG>"value"{WHITESPACE}*"="            { return VALUE_ATTR; }

<IN_TAG>"/>"                { BEGIN(INITIAL); return SELF_CLOSE; }
<IN_TAG>">"                 { BEGIN(INITIAL); return '>'; }

<IN_TAG>{WHITESPACE}        { /* skip whitespace */ }
<IN_TAG>{STRING}            { yylval.str = strdup(yytext); return STRING; }
<IN_TAG>{IDENTIFIER}        { yylval.str = strdup(yytext); return TEXT; }

{WHITESPACE}        { /* skip whitespace */ }
{STRING}            { yylval.str = strdup(yytext); return STRING; }
{POS_INT}           { yylval.num = atoi(yytext); return POS_INT; }

[^<>]+              { yylval.str = strdup(yytext); return TEXT; }

.                   { return yytext[0]; }
%%
