%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern FILE *yyin;
extern int yylex();
extern int yyparse();
extern int yylineno;
int semantic_errors = 0;

void yyerror(const char *s);

#define MAX_IDS 1000
typedef struct {
    char id[256];  
    int line_number;
} id_info;

id_info id_array[MAX_IDS];
int id_count = 0;

id_info input_id_array[MAX_IDS];
int input_id_count = 0;

typedef struct {
    char input_id[256]; 
    char label_id[256]; 
    int line_number;
} label_connections_info;

label_connection_info label_connections[MAX_IDS];
int label_connection_count = 0;

//EROTIMA A TITLE LENGTH
void check_title_length(const char *title, int line) {
    if (!title) return;
    
    int len = strlen(title);
    if (len > 60) {
        fprintf(stderr, " Error at line %d: Title text exceeds 60 characters (current: %d)\n", 
                line, len);
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

//EROTIMA B CHECK ID 
void check_id(const char *id, int line) {
    if (!id) return;
    
    const char* cleaned_id = strip_quotes(id);
    if (!cleaned_id) return;
    
    // Check if ID already exists
    for (int i = 0; i < id_count; i++) {
        if (strcmp(id_array[i].id, cleaned_id) == 0) {
            fprintf(stderr, " Error at line %d: Duplicate ID '%s' (Same at line %d)\n", 
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

void check_input_id(const char *id, int line) {
    if (!id) return;
    
    const char* cleaned_id = strip_quotes(id);
    if (!cleaned_id) return;
    
    if (input_id_count < MAX_IDS) {
        strcpy(input_id_array[input_id_count].id, cleaned_id);
        input_id_array[input_id_count].line_number = line;
        input_id_count++;
    }
}

//EROTIMA C HREF
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

//EROTIMA D SRC
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

//EROTIMA E TYPE
const char *known_type_schemes[] = {
    "text", "checkbox", "radio", "submit"
};

#define NUM_TYPE_SCHEMES (sizeof(known_type_schemes) / sizeof(known_type_schemes[0]))

int type_submit = 0;
int last_type_submit = 0;

void check_type(const char *type, int line){
    if (!type) return;
    
    const char* cleaned_type = strip_quotes(type);
    int valid = 0;
    
    for (int i = 0; i < NUM_TYPE_SCHEMES; i++){
        if(strcmp(cleaned_type, known_type_schemes[i]) == 0){
           valid = 1;
           break;
        }
    }
    
    if (!valid){
        fprintf(stderr, "Semantic Error at line %d: Invalid input type '%s'\n", line, cleaned_type);
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
            if (type_submit && !last_type_submit) {
                fprintf(stderr, "Semantic Error at line %d: Submit button must be the last input element\n", line);
                semantic_errors++;
                type_submit = 0;
            }
            last_type_submit = 0;
        }
    }
}

//EROTIMA F LABEL
void check_id_for(const char *for_id, const char *label_id, int line){
    if (!for_id || !label_id) return;
    
    const char* striped_for_id = strip_quotes(for_id);
    const char* striped_label_id = strip_quotes(label_id);
    
    int input_found = 0;
    for (int i = 0; i < input_id_count; i++) {
        if (strcmp(input_id_array[i].id, for_id) == 0) {
            input_found = 1;
            break;
        }
    }
    if (!input_found) {
        fprintf(stderr, "Error at line %d: The label 'for' attribute '%s' doesn't exist\n", line, striped_for_id);
        semantic_errors++;
        return;
    }
    
    for (int i = 0; i < label_connection_count; i++) {
        if (strcmp(label_connections[i].input_id, for_id) == 0) {
            fprintf(stderr, "Error at line %d: Element '%s' already connected to label '%s' (line %d)\n", 
                    line, striped_for_id, label_connections[i].label_id, label_connections[i].line_number);
            semantic_errors++;
            return;
        }
    }
    
    if (label_connection_count < MAX_IDS) {
        strcpy(label_connections[label_connection_count].input_id,striped_for_id); 
        strcpy(label_connections[label_connection_count].label_id,striped_label_id); 
        label_connections[label_connection_count].line_number = line;
        label_connection_count++;
    }
}

//EROTIMA E STYLE
int is_valid_style_property(const char* prop,const char* val) {
    if(strcmp(prop, "background_color") == 0||strcmp(prop, "color") == 0 || strcmp(prop, "font_family")==0) {
        return 1;
    }
    if(strcmp(prop, "font_size") == 0) {
        int len = strlen(val);
        if(len > 2) {
            if((val[len-1] == '%')||(strncmp(val+len-2, "px",2) == 0)) {
                return 1;
            }
        }
        return 0;
    }
    return 0;
}

void check_style(const char* style_str, int line) {
    if(!style_str) return;
    
    char buffer[1024];
    char seen_props[MAX_IDS][64];
    int unique_count = 0;
    
    strcpy(buffer, style_str);
    
    for(char* segment = strtok(buffer, ";"); segment && unique_count < MAX_IDS; segment = strtok(NULL, ";")) {
        char* delimiter = strchr(segment, ':');
        
        if(!delimiter) {
            fprintf(stderr, " Line %d: malformed style entry '%s' (missing colon)\n",line,segment);
            semantic_errors++;
            continue;
        }
        
        *delimiter = '\0';
        char* property = segment;
        char* value = delimiter+1;
        
        // Strip leading spaces
        while(isspace(*property)) property++;
        while(isspace(*value)) value++;
        
        // Check if we've encountered this property already
        int already_seen = 0;
        for(int idx = 0; idx < unique_count; idx++) {
            if(!strcmp(seen_props[idx], property)) {
                fprintf(stderr, " Line %d: property '%s' appears multiple times\n", line, property);
                semantic_errors++;
                already_seen = 1;
                break;
            }
        }
        
        if(already_seen) continue;
        
        if(is_valid_style_property(property, value)) {
            strcpy(seen_props[unique_count++], property);
        } else {
            fprintf(stderr, " Line %d: invalid property-value pair '%s:%s'\n", line, property, value);
            semantic_errors++;
        }
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
        check_style($4, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
        check_style($2, yylineno);
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
        check_style($4, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
        check_style($2, yylineno);
    }
  | ID_ATTR STRING {check_id($2, yylineno);}
  | STYLE_ATTR STRING {check_style($2, yylineno);}
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
        check_input_id($2, yylineno);
        check_type($4, yylineno);
    }
  | TYPE_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
        check_input_id($4, yylineno);
        check_type($2, yylineno);
    }
;

input_optional_attrs:
    VALUE_ATTR STRING STYLE_ATTR STRING {check_style($4, yylineno);}
  | STYLE_ATTR STRING VALUE_ATTR STRING {check_style($2, yylineno);}
  | VALUE_ATTR STRING
  | STYLE_ATTR STRING {check_style($2, yylineno);}
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
        check_id_for($4, $2, yylineno);
    }
  | FOR_ATTR STRING ID_ATTR STRING {
        check_id($4, yylineno);
        check_id_for($2, $4, yylineno);
    }
;

label_style_attr:
    STYLE_ATTR STRING {check_style($2, yylineno);}
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
        check_style($4, yylineno);
    }
  | STYLE_ATTR STRING ID_ATTR STRING {
        check_style($2, yylineno);
        check_id($4, yylineno);
    }
  | ID_ATTR STRING {
        check_id($2, yylineno);
    }
  | STYLE_ATTR STRING {
        check_style($2, yylineno);
    }
  | /* empty */
;

%%
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {

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

    id_count = 0;
    input_id_count = 0;
    label_connection_count = 0;
    
    int parsed = yyparse();

    if (parsed== 0 && semantic_errors == 0) {
        printf("\nParsing successful! No semantic errors found.\n");
    } else if (parsed== 0 && semantic_errors > 0) {
        printf("\nParsing completed with %d semantic error(s).\n", semantic_errors);
        parsed= 1;
    } else {
        printf("\nParsing failed at line %d\n", yylineno);
    }

    fclose(yyin);
    return res;
}
