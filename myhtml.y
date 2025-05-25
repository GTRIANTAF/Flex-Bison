%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yylex();
extern int yyparse();
extern int yylineno;
int semantic_errors = 0;

void yyerror(const char *s);

#define MAX_IDS 1000
typedef struct {
    char *id;
    int line_number;
} id_info_t;

id_info_t id_array[MAX_IDS];
int id_count = 0;

//EROTIMA A TITLE LENGTH
void check_title_length(const char *title, int line) {
    if (!title) return;
    
    int len = strlen(title);
    if (len > 60) {
        fprintf(stderr, "Semantic Error at line %d: Title text exceeds 60 characters (current: %d)\n", 
                line, len);
        semantic_errors++;
    }
}

//EROTIMA B CHECK ID
void check_id(const char *id, int line) {
    if (!id) return;
    
    // Check if ID already exists
    for (int i = 0; i < id_count; i++) {
        if (strcmp(id_array[i].id, id) == 0) {
            fprintf(stderr, "Semantic Error at line %d: Duplicate ID '%s' (first declared at line %d)\n", 
                    line, id, id_array[i].line_number);
            semantic_errors++;
            return;
        }
    }
    
    // Add new ID to array
    if (id_count < MAX_IDS) {
        id_array[id_count].id = strdup(id);
        id_array[id_count].line_number = line;
        id_count++;
    }
}

//EROTIMA C HREF
void check_href_value(const char *href, int line) {
    if (!href) return;
    
    // Remove quotes if present
    char *clean_href = strdup(href);
    int len = strlen(clean_href);
    if ((clean_href[0] == '"' && clean_href[len-1] == '"')){
        clean_href[len-1] = '\0';
    }
    //internal check
    if (clean_href[0] == '#') {
        // Internal link - just check it's not empty after #
        if (strlen(clean_href) <= 1) {
            fprintf(stderr, "Semantic Error at line %d: Empty internal link '#'\n", line);
            semantic_errors++;
        }
    }//absolute check
    else if (strstr(clean_href, "://") != NULL) {
        // Absolute URL - basic check passed
        printf("INFO: Found absolute URL: %s\n", clean_href);
    }//relative check
    else {
        // Relative URL - basic check passed
        printf("INFO: Found relative URL: %s\n", clean_href);
    }
}

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

%token SELF_CLOSE COMMENT_OPEN COMMENT_CLOSE

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
;

title:
    TITLE_OPEN title_content TITLE_CLOSE
;

title_content:
    TEXT {check_title_length($1, yylineno); }
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
    element
  | comment
;

element:
    p_tag
  | a_tag
  | img_tag
  | form_tag
  | div_tag
;

comment:
    COMMENT_OPEN COMMENT_TEXT COMMENT_CLOSE
;

p_tag:
    P_OPEN p_attributes '>' p_content P_CLOSE
;

p_attributes:
    ID_ATTR STRING p_style_attr {check_id($2, yylineno);}
;

p_style_attr:
    STYLE_ATTR TEXT
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
    HREF_ATTR STRING ID_ATTR STRING {
	check_id($4, yylineno);
	check_href_value($2, yylineno);
	}
  | ID_ATTR STRING HREF_ATTR STRING {
	check_id($2, yylineno);
	check_href_value($4, yylineno);
	}
;

a_content:
    /* empty */
  | TEXT
  | img_tag
  | TEXT img_tag
  | img_tag TEXT
;

img_tag:
    IMG_OPEN img_attributes '>'
;

img_attributes:
    img_core_attrs img_size_attrs
;

img_core_attrs:
    ID_ATTR STRING SRC_ATTR STRING ALT_ATTR STRING {check_id($2, yylineno);}
  | SRC_ATTR STRING ALT_ATTR STRING ID_ATTR STRING {check_id($6, yylineno);}
  | ALT_ATTR STRING ID_ATTR STRING SRC_ATTR STRING {check_id($4, yylineno);}
  | ALT_ATTR STRING SRC_ATTR STRING ID_ATTR STRING {check_id($6, yylineno);}
  | ID_ATTR STRING ALT_ATTR STRING SRC_ATTR STRING {check_id($2, yylineno);}
  | SRC_ATTR STRING ID_ATTR STRING ALT_ATTR STRING {check_id($4, yylineno);}
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
    ID_ATTR STRING form_style_attr {check_id($2, yylineno);}
  | form_style_attr ID_ATTR STRING {check_id($3, yylineno);}
;

form_style_attr:
    STYLE_ATTR STRING
  | /* empty */
;

form_elements:
    form_element_list
  | /* empty */
;

form_element_list:
    form_element_list form_element
  | form_element
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
    ID_ATTR STRING TYPE_ATTR STRING {check_id($2, yylineno);}
  | TYPE_ATTR STRING ID_ATTR STRING {check_id($4, yylineno);}
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
    ID_ATTR STRING FOR_ATTR STRING {check_id($2, yylineno);}
  | FOR_ATTR STRING ID_ATTR STRING {check_id($4, yylineno);}
;

label_style_attr:
    STYLE_ATTR STRING
  | /* empty */
;

label_content:
    TEXT
  | /* empty */
;

div_tag:
    DIV_OPEN div_attributes '>' body_elements DIV_CLOSE
;

div_attributes:
    ID_ATTR STRING div_style_attr {check_id($2, yylineno);}
  | div_style_attr ID_ATTR STRING {check_id($3, yylineno);}
;

div_style_attr:
    STYLE_ATTR STRING
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

    id_count = 0;
	
    int res = yyparse();

    if (res == 0 && semantic_errors == 0) {
        printf("\nParsing successful! No semantic errors found.\n");
    } else if (res == 0 && semantic_errors > 0) {
        printf("\nParsing completed with %d semantic error(s).\n", semantic_errors);
        res = 1;
    } else {
        printf("\nParsing failed at line %d\n", yylineno);
    }

    fclose(yyin);
    return res;
}