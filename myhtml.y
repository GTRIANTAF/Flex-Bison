%{
#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
extern int yylex();
extern int yyparse();
extern int yylineno;

void yyerror(const char *s);

%}

%union {
    char* str;
    int num;
}

%token <str> STRING ID TEXT COMMENT_TEXT
%token <num> POS_INT
%token WHITESPACE

%token MYHTML_OPEN MYHTML_CLOSE HEAD_OPEN HEAD_CLOSE META_OPEN TITLE_OPEN TITLE_CLOSE
%token BODY_OPEN BODY_CLOSE A_OPEN A_CLOSE P_OPEN P_CLOSE IMG_OPEN
%token FORM_OPEN FORM_CLOSE INPUT_OPEN LABEL_OPEN LABEL_CLOSE DIV_OPEN DIV_CLOSE

%token ID_ATTR CHARSET_ATTR NAME_ATTR STYLE_ATTR CONTENT_ATTR HREF_ATTR SRC_ATTR ALT_ATTR
%token WIDTH_ATTR HEIGHT_ATTR FOR_ATTR TYPE_ATTR VALUE_ATTR

%token COMMENT_OPEN COMMENT_CLOSE

%start myHTML

%%

myHTML:
    MYHTML_OPEN optional_head body MYHTML_CLOSE
;

optional_head:
    head
  | /* empty */
;

head:
    HEAD_OPEN head_elements HEAD_CLOSE
;

head_elements:
    head_element_list
  | /* empty */
;

head_element_list:
    head_element_list head_element
  | head_element
;

head_element:
    title
  | meta
  | comment
;

title:
    TITLE_OPEN title_content TITLE_CLOSE
;

title_content:
    TEXT
  | /* empty */
;

meta:
    META_OPEN CHARSET_ATTR STRING '>'
  | META_OPEN NAME_ATTR STRING CONTENT_ATTR STRING '>'
;

body:
    BODY_OPEN body_elements BODY_CLOSE
;

body_elements:
    body_element_list
  | /* empty */
;

body_element_list:
    body_element_list body_element
  | body_element
;

body_element:
    p_tag
  | a_tag
  | img_tag
  | form_tag
  | div_tag
  | comment
;

comment:
    COMMENT_OPEN COMMENT_TEXT COMMENT_CLOSE
;

p_tag:
    P_OPEN p_attributes '>' p_content P_CLOSE
;

p_attributes:
    ID_ATTR STRING STYLE_ATTR STRING
  | STYLE_ATTR STRING ID_ATTR STRING
  | ID_ATTR STRING
  | /* empty */
;

p_content:
    TEXT
  | /* empty */
;

a_tag:
    A_OPEN a_attributes '>' a_content A_CLOSE
;

a_attributes:
    HREF_ATTR STRING ID_ATTR STRING
  | ID_ATTR STRING HREF_ATTR STRING
  | HREF_ATTR STRING
  | ID_ATTR STRING
  | /* empty */
;

a_content:
    a_content_list
  | /* empty */
;

a_content_list:
    a_content_list a_content_items
  | a_content_items
;

a_content_items:
    TEXT
  | img_tag
  | comment
;

img_tag:
    IMG_OPEN img_attributes '>'
;

img_attributes:
    img_core_attrs img_size_attrs
;

img_core_attrs:
    ID_ATTR STRING SRC_ATTR STRING ALT_ATTR STRING
  | SRC_ATTR STRING ALT_ATTR STRING ID_ATTR STRING
  | ALT_ATTR STRING ID_ATTR STRING SRC_ATTR STRING
  | ALT_ATTR STRING SRC_ATTR STRING ID_ATTR STRING
  | ID_ATTR STRING ALT_ATTR STRING SRC_ATTR STRING
  | SRC_ATTR STRING ID_ATTR STRING ALT_ATTR STRING
  | SRC_ATTR STRING ALT_ATTR STRING
  | ALT_ATTR STRING SRC_ATTR STRING
;

img_size_attrs:
    WIDTH_ATTR STRING HEIGHT_ATTR STRING
  | HEIGHT_ATTR STRING WIDTH_ATTR STRING
  | WIDTH_ATTR STRING
  | HEIGHT_ATTR STRING
  | /* empty */
;

form_tag:
    FORM_OPEN form_attributes '>' form_elements FORM_CLOSE
;

form_attributes:
    ID_ATTR STRING STYLE_ATTR STRING
  | STYLE_ATTR STRING ID_ATTR STRING
  | ID_ATTR STRING
  | STYLE_ATTR STRING
  | /* empty */
;

form_elements:
    form_element_list
  | /* empty */
;

form_element_list:
    form_element_list form_or_comment
  | form_or_comment
;

form_or_comment:
    form_element
  | comment
;

form_element:
    input_tag
  | label_tag
;

input_tag:
    INPUT_OPEN input_attributes '>'
;

input_attributes:
    input_core_attrs input_optional_attrs
;

input_core_attrs:
    ID_ATTR STRING TYPE_ATTR STRING
  | TYPE_ATTR STRING ID_ATTR STRING
;

input_optional_attrs:
    VALUE_ATTR STRING STYLE_ATTR STRING
  | STYLE_ATTR STRING VALUE_ATTR STRING
  | VALUE_ATTR STRING
  | STYLE_ATTR STRING
  | /* empty */
;

label_tag:
    LABEL_OPEN label_attributes '>' label_content LABEL_CLOSE
;

label_attributes:
    label_core_attrs label_style_attr
;

label_core_attrs:
    ID_ATTR STRING FOR_ATTR STRING
  | FOR_ATTR STRING ID_ATTR STRING
;

label_style_attr:
    STYLE_ATTR STRING
  | /* empty */
;

label_content:
    TEXT
  | comment
  | /* empty */
;

div_tag:
    DIV_OPEN div_attributes '>' body_elements DIV_CLOSE
;

div_attributes:
    ID_ATTR STRING STYLE_ATTR STRING
  | STYLE_ATTR STRING ID_ATTR STRING
  | ID_ATTR STRING
  | STYLE_ATTR STRING
  | /* empty */
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Could not open input file");
        return 1;
    }

    rewind(yyin); // Go to the start of the file
    int c;
    while ((c = fgetc(yyin)) != EOF) {
        putchar(c);
    }

    // Reset again to allow parsing
    rewind(yyin);
	
    int result = yyparse();

    if (result == 0) {
        printf("\nParsing successful!\n");
    } else {
        printf("\nParsing failed at line %d\n", yylineno);
    }

    fclose(yyin);
    return result;
}
