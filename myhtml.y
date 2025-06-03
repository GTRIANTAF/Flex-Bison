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

typedef struct {
    char *input_id;
    char *label_id;
    int line_number;
} label_connection_t;

label_connection_t label_connections[MAX_IDS];
int label_connected_input = 0;

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
    
    if (id_count < MAX_IDS) {
        id_array[id_count].id = strdup(id);
        id_array[id_count].line_number = line;
        id_count++;
    }
}

//EROTIMA C HREF
const char *known_schemes[] = {
    "http://",
    "https://",
    "ftp://",
    "mailto:",
    "file://"
};

#define NUM_SCHEMES (sizeof(known_schemes) / sizeof(known_schemes[0]))

int url_is_correct(const char *str, const char *prefix) {
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

int is_absolute_url_href(const char *href) {
    for (int i = 0; i < NUM_SCHEMES; i++) {
        if (url_is_correct(href, known_schemes[i])) {
            return 1;
        }
    }
    return 0;
}

char* strip_quotes(const char* input) {
    if (!input) return NULL;
    
    int len = strlen(input);
    if (len >= 2 && ((input[0] == '"' && input[len-1] == '"'))) {
        char* result = malloc(len - 1);
        strncpy(result, input + 1, len - 2);
        result[len - 2] = '\0';
        return result;
    }
    
    return strdup(input);
}


void check_href(const char *href, int line) {
    if (!href) return;
    
    char* cleaned_href = strip_quotes(href);
    if (!cleaned_href) return;
   
    if (cleaned_href[0] == '#') {
        const char *ref_id = href + 1;
        int found = 0;
        for (int i = 0; i < id_count; i++) {
            if (strcmp(id_array[i].id, ref_id) == 0) {
                found = 1;
                break;
            }
        }
        if (!found) {
            fprintf(stderr, "Semantic Error at line %d: href references non-existent ID '%s'\n", 
                    line, ref_id);
            semantic_errors++;
        } else {
            printf("Info at line %d: href is an internal reference to ID '%s'\n", line, ref_id);
        }
    } else if (is_absolute_url_href(href)) {
        printf("Info at line %d: href is an absolute URL: %s\n", line, href);
    } else {
        printf("Info at line %d: href is a relative URL: %s\n", line, href);
    }
}


//EROTIMA D SCR
int is_absolute_url_src(const char *src) {
    for (int i = 0; i < NUM_SCHEMES; i++) {
        if (url_is_correct(src, known_schemes[i])) {
            return 1;
        }
    }
    return 0;
}

void check_src(const char *src, int line) {
    if (!src) return;
    
    if (is_absolute_url_src(src)) {
        printf("Info at line %d: src is an absolute URL: %s\n", line, src);
    } else {
        printf("Info at line %d: src is a relative URL: %s\n", line, src);
    }
}

//EROTIMA E TYPE
const char *known_type_schemes[] = {
    "text",
    "checkbox",
    "radio",
    "submit"
};

#define NUM_TYPE_SCHEMES (sizeof(known_type_schemes) / sizeof(known_type_schemes[0]))

int type_submit = 0;
int last_type_submit = 0;

void check_type(const char *type, int line){
    if (!type) return;
    
    char* cleaned_type = strip_quotes(type);
    int valid = 0;
    for (int i=0; i< NUM_TYPE_SCHEMES; i++){
    	if(strcmp(cleaned_type, known_type_schemes[i]) == 0){
	   valid = 1;
	   break;
	}
    }
    if (!valid){
	fprintf(stderr, "Semantic Error at line %d: Invalid input type '%s'", line, cleaned_type);
        semantic_errors++;
    } else {
	if (strcmp(cleaned_type, "submit") == 0) {
            if (type_submit) {
                fprintf(stderr, "Semantic Error at line %d: One submit button allowed\n", line);
                semantic_errors++;
            } else {
               type_submit = 1;
            }
             last_type_submit = 1;
        } else {
            if (type_submit && ! last_type_submit) {
                fprintf(stderr, "Semantic Error at line %d: Submit button must be the last input element\n", line);
                semantic_errors++;
                type_submit = 0;
            }
            last_type_submit = 0;
        }
    }

}

//EROTIMA F LABEL
void check_id_for(const char *for_id,const char *label_id, int line){
    if (!for_id || !label_id) return;
    
    int input_found = 0;
    for (int i = 0; i < input_id_count; i++) {
        if (strcmp(input_id_array[i].id, for_id) == 0) {
            found_input = 1;
            break;
        }
    }
    if (!found_input) {
        fprintf(stderr, "Semantic Error at line %d: The label 'for' of attribute %s doesnt exist\n", line, for_id);
        semantic_errors++;
        return;
    }
    for (int i = 0; i < label_connected_input; i++) {
        if (strcmp(label_connections[i].input_id, for_id) == 0) {
            fprintf(stderr, "Semantic Error at line %d: Element '%s' is connected to label '%s'\n", line, for_id, label_connections[i].label_id, label_connections[i].line_number);
            semantic_errors++;
            return;
        }
    }
    if (label_connected_input < MAX_IDS) {
        label_connections[label_connection_count].input_id = strdup(for_id);
        label_connections[label_connection_count].label_id = strdup(label_id);
        label_connections[label_connection_count].line_number = line;
        label_connected_input;
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
	check_href($2, yylineno);
	}
  | ID_ATTR STRING HREF_ATTR STRING {
	check_id($2, yylineno);
	check_href($4, yylineno);
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
    ID_ATTR STRING TYPE_ATTR STRING {
	check_id($2, yylineno);
    	check_type($4, yylineno);
	}
  | TYPE_ATTR STRING ID_ATTR STRING {
	check_id($4, yylineno);
	check_type($2, yylineno);
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