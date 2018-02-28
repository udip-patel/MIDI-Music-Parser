/*
antlr4 -no-listener Eval.g4
grun Eval start
*/
grammar Eval;

/*
# Parser
# expression ::= ["+" | '-'] term {("+" | "-") term)}
# term ::= factor {("*" | "/") factor}
# factor ::= integer | "(" expression ")"
*/
start
    :   expression EOF {System.out.println($expression.value);}
    ;

expression
returns [int value]
    :   ( PLUS | uMinus=MINUS )? term { $value = ($uMinus != null ? -1 : 1) * $term.value; }
        ( PLUS term     { $value += $term.value; }
        | MINUS term    { $value -= $term.value; }
        )*
    ;

term
returns [int value]
    :   factor { $value = $factor.value; }
        ( ( TIMES | DIVIDE ) factor
            { if ($DIVIDE != null)
                  $value /= $factor.value;
              else
                  $value *= $factor.value;
            }
        )*
    ;

factor
returns [int value]
    : NUMBER                     { $value = $NUMBER.int; }
    | L_PAREN expression R_PAREN { $value = $expression.value; }
    ;

//Scanner

PLUS : '+' ;
MINUS : '-' ;
TIMES : '*' ;
DIVIDE : '/' ;
L_PAREN : '(' ;
R_PAREN : ')' ;

NUMBER : [0-9]+ ;

WS : [ \t\n\r]+ -> skip;