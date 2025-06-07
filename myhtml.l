%{
#include "html.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}
%option noyywrap
%option yylineno

DIGIT       [0-9]
STRING      \"[^\"]*\"|\'[^\']*\'
POS_INT     [1-9]{DIGIT}*|0
WHITESPACE  [ \t\n\r]+
IDENTIFIER  [a-zA-Z][a-zA-Z0-9_-]*

%x COMMENT
%x TAG_ATTR

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
"<meta"             { BEGIN(TAG_ATTR); return META_OPEN; }
"<title>"           { return TITLE_OPEN; }
"</title>"          { return TITLE_CLOSE; }
"<body>"            { return BODY_OPEN; }
"</body>"           { return BODY_CLOSE; }
"<a"                { BEGIN(TAG_ATTR); return A_OPEN; }
"</a>"              { return A_CLOSE; }
"<p"                { BEGIN(TAG_ATTR); return P_OPEN; }
"</p>"              { return P_CLOSE; }
"<img"              { BEGIN(TAG_ATTR); return IMG_OPEN; }
"<form"             { BEGIN(TAG_ATTR); return FORM_OPEN; }
"</form>"           { return FORM_CLOSE; }
"<input"            { BEGIN(TAG_ATTR); return INPUT_OPEN; }
"<label"            { BEGIN(TAG_ATTR); return LABEL_OPEN; }
"</label>"          { return LABEL_CLOSE; }
"<div"              { BEGIN(TAG_ATTR); return DIV_OPEN; }
"</div>"            { return DIV_CLOSE; }

<TAG_ATTR>"id"{WHITESPACE}*"="               { return ID_ATTR; }
<TAG_ATTR>"charset"{WHITESPACE}*"="          { return CHARSET_ATTR; }
<TAG_ATTR>"name"{WHITESPACE}*"="             { return NAME_ATTR; }
<TAG_ATTR>"style"{WHITESPACE}*"="            { return STYLE_ATTR; }
<TAG_ATTR>"content"{WHITESPACE}*"="          { return CONTENT_ATTR; }
<TAG_ATTR>"href"{WHITESPACE}*"="             { return HREF_ATTR; }
<TAG_ATTR>"src"{WHITESPACE}*"="              { return SRC_ATTR; }
<TAG_ATTR>"alt"{WHITESPACE}*"="              { return ALT_ATTR; }
<TAG_ATTR>"width"{WHITESPACE}*"="            { return WIDTH_ATTR; }
<TAG_ATTR>"height"{WHITESPACE}*"="           { return HEIGHT_ATTR; }
<TAG_ATTR>"for"{WHITESPACE}*"="              { return FOR_ATTR; }
<TAG_ATTR>"type"{WHITESPACE}*"="             { return TYPE_ATTR; }
<TAG_ATTR>"value"{WHITESPACE}*"="            { return VALUE_ATTR; }

<TAG_ATTR>">"                 { BEGIN(INITIAL); return '>'; }

<TAG_ATTR>{WHITESPACE}        { /* skip whitespace */ }
<TAG_ATTR>{STRING}            { yylval.str = strdup(yytext); return STRING; }
<TAG_ATTR>{IDENTIFIER}        { yylval.str = strdup(yytext); return STRING; }

{WHITESPACE}        { /* skip whitespace */ }
{STRING}            { yylval.str = strdup(yytext); return STRING; }
{POS_INT}           { yylval.num = atoi(yytext); return POS_INT; }

[^<>]+              { yylval.str = strdup(yytext); return TEXT; }

.                   { return yytext[0]; }
%%
