%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yylex();
extern int yyparse();
extern int yylineno;
int semantic_errors = 0;

#define MAX_IDS 1000
typedef struct {
    char id[256];  
    int line_number;
} id_info_t;

id_info_t id_array[MAX_IDS];
int id_count = 0;

void check_title_length(const char *title, int line) {
    if (!title) return;
    
    int len = strlen(title);
    if (len > 60) {
        fprintf(stderr, "Error at line %d: Title text bigger than 60 characters (current: %d)\n", line, len);
        semantic_errors++;
    }
}

const char* strip_quotes(const char* input) {
    static char buffer[512]; 
    
    if (!input) return NULL;
    
    int len = strlen(input);
    if (len >= 2 && ((input[0] == '"' && input[len-1] == '"'))) {
        strncpy(buffer, input+1,len-2);
        buffer[len-2] = '\0';
        return buffer;
    }
    
    strcpy(buffer, input);
    return buffer;
}

void check_id(const char *id, int line) {
    if (!id) return;
    
    const char* cleaned_id = strip_quotes(id);
    if (!cleaned_id) return;
    
    // Check if ID already exists
    for (int i = 0; i < id_count; i++) {
        if (strcmp(id_array[i].id, cleaned_id) == 0) {
            fprintf(stderr, "Error at line %d: Duplicate ID '%s' (Same at line %d)\n", 
                    line, cleaned_id, id_array[i].line_number);
            semantic_errors++;
            return;
        }
    }
    
    if (id_count < MAX_IDS) {
        strcpy(id_array[id_count].id, cleaned_id);
        id_array[id_count].line_number = line;
        id_count++;
    }
}

const char *known_schemes[] = {
    "http://", "https://", "ftp://", "mailto:", "file://"
};

#define NUM_SCHEMES (sizeof(known_schemes) / sizeof(known_schemes[0]))

int is_absolute_url(const char *url) {
    for (int i = 0; i < NUM_SCHEMES; i++) {
        if (strncmp(url, known_schemes[i], strlen(known_schemes[i])) == 0) {
            return 1;
        }
    }
    return 0;
}

void check_href(const char *href, int line) {
    if (!href) return;
    
    const char* cleaned_href = strip_quotes(href);
    if (!cleaned_href) return;
   
    if (cleaned_href[0] == '#') {
        const char *ref_id = cleaned_href + 1;
        int found = 0;
        for (int i = 0; i < id_count; i++) {
            if (strcmp(id_array[i].id, ref_id) == 0) {
                found = 1;
                break;
            }
        }
        if (!found) {
            fprintf(stderr, " Error at line %d: href references non-existent ID '%s'\n", 
                    line, ref_id);
            semantic_errors++;
        } else {
            printf("Line %d: href is an internal reference to ID '%s'\n", line, ref_id);
        }
    } else if (is_absolute_url(cleaned_href)) {
        printf("Line %d: href is an absolute URL: %s\n", line, cleaned_href);
    } else {
        printf("Line %d: href is a relative URL: %s\n", line, cleaned_href);
    }
}

void check_src(const char *src, int line) {
    if (!src) return;
    
    const char* cleaned_src = strip_quotes(src);
    if (!cleaned_src) return;
    
    if (is_absolute_url(cleaned_src)) {
        printf("Info at line %d: src is an absolute URL: %s\n", line, cleaned_src);
    } else {
        printf("Info at line %d: src is a relative URL: %s\n", line, cleaned_src);
    }
}

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
    ID_ATTR STRING STYLE_ATTR STRING {
        check_id($2, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
    }
  | ID_ATTR STRING {check_id($2, yylineno);}
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
	check_href($2, yylineno);
    }
  | ID_ATTR STRING HREF_ATTR STRING {
        check_id($2, yylineno);
	check_href($4, yylineno);
    }
  | HREF_ATTR STRING {
	check_href($2, yylineno);
    }
  | ID_ATTR STRING {
        check_id($2, yylineno);
    }
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
    ID_ATTR STRING SRC_ATTR STRING ALT_ATTR STRING {
        check_id($2, yylineno);
        check_src($4, yylineno);
    }
  | SRC_ATTR STRING ALT_ATTR STRING ID_ATTR STRING {
        check_id($6, yylineno);
        check_src($2, yylineno);
    }
  | ALT_ATTR STRING ID_ATTR STRING SRC_ATTR STRING {
        check_id($4, yylineno);
        check_src($6, yylineno);
    }
  | ALT_ATTR STRING SRC_ATTR STRING ID_ATTR STRING {
        check_id($6, yylineno);
        check_src($4, yylineno);
    }
  | ID_ATTR STRING ALT_ATTR STRING SRC_ATTR STRING {
        check_id($2, yylineno);
        check_src($6, yylineno);
    }
  | SRC_ATTR STRING ID_ATTR STRING ALT_ATTR STRING {
        check_id($4, yylineno);
        check_src($2, yylineno);
    }
  | SRC_ATTR STRING ALT_ATTR STRING {
        check_src($2, yylineno);
    }
  | ALT_ATTR STRING SRC_ATTR STRING {
        check_src($4, yylineno);
    }
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
    ID_ATTR STRING STYLE_ATTR STRING {
        check_id($2, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
    }
  | ID_ATTR STRING {check_id($2, yylineno);}
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
    ID_ATTR STRING TYPE_ATTR STRING {
        check_id($2, yylineno);
    }
  | TYPE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
    }
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
    ID_ATTR STRING FOR_ATTR STRING {
        check_id($2, yylineno);
    }
  | FOR_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
    }
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
    ID_ATTR STRING STYLE_ATTR STRING {
        check_id($2, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
    }
  | ID_ATTR STRING {
        check_id($2, yylineno);
    }
  | STYLE_ATTR STRING {
    }
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

   if (result == 0 && semantic_errors == 0) {
        printf("\nParsing successful! No semantic errors found.\n");
    } else if (result == 0 && semantic_errors > 0) {
        printf("\nParsing completed with %d semantic error(s).\n", semantic_errors);
        result = 1;
    } else {
        printf("\nParsing failed at line %d\n", yylineno);
    }

    fclose(yyin);
    return result;
}
