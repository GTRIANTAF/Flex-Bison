%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylval;
char* string_val;

%}

%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z]
STRING      \"([^\"\n]|\\\")*\"|\'([^\'\n]|\\\')*\'
ID          {LETTER}({LETTER}|{DIGIT}|_)*
POS_INT     [1-9]{DIGIT}*|0
WHITESPACE  [ \t\n]
COMMENT     "<!--"([^-]|-[^-]|"--"([^>]|[ \t\n\r]+[^>]))*"-->"
SELF_CLOSE  "/>"
ATTR_VALUE  {STRING}|{POS_INT}

%%

"<MYHTML>"      { return MYHTML_OPEN; }
"</MYHTML>"     { return MYHTML_CLOSE; }
"<head>"        { return HEAD_OPEN; }
"</head>"       { return HEAD_CLOSE; }
"<title>"       { return TITLE_OPEN; }
"</title>"      { return TITLE_CLOSE; }
"<meta"         { return META_OPEN; }
"<body>"        { return BODY_OPEN; }
"</body>"       { return BODY_CLOSE; }
"<p"            { return P_OPEN; }
"</p>"          { return P_CLOSE; }
"<a"            { return A_OPEN; }
"</a>"          { return A_CLOSE; }
"<img"          { return IMG_OPEN; }
"<form"         { return FORM_OPEN; }
"</form>"       { return FORM_CLOSE; }
"<input"        { return INPUT_OPEN; }
"<label"        { return LABEL_OPEN; }
"</label>"      { return LABEL_CLOSE; }
"<div"          { return DIV_OPEN; }
"</div>"        { return DIV_CLOSE; }

"id="           { return ID_ATTR; }
"name="         { return NAME_ATTR; }
"charset="      { return CHARSET_ATTR; }
"content="      { return CONTENT_ATTR; }
"style="        { return STYLE_ATTR; }
"href="         { return HREF_ATTR; }
"src="          { return SRC_ATTR; }
"alt="          { return ALT_ATTR; }
"width="        { return WIDTH_ATTR; }
"height="       { return HEIGHT_ATTR; }
"for="          { return FOR_ATTR; }
"type="         { return TYPE_ATTR; }
"value="        { return VALUE_ATTR; }

{COMMENT}       { /* Skip comments */ }
{SELF_CLOSE}    { return SELF_CLOSE; }
{STRING}        { string_val = strdup(yytext); return STRING; }
{POS_INT}       { yylval = atoi(yytext); return POS_INT; }
{WHITESPACE}    ; // Skip whitespace
.               { return yytext[0]; } // Single chars like >, =

%%

int main() {
    yylex();
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Lexer Error: %s\n", s);
}
