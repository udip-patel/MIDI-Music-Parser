grammar PythonMacros;

//Included in the generated .java file above the class definition
@header {
import java.util.*;
}

//Included in the body of the generated class. This is the place
//to define fields, method, nested classes etc.
@members {

}



/* Parser
# program = <instrumentBlock>*<EOF>
# instrumentBlock = <scopeHeader>'{'(<playStmt>|<waitStmt>)*'}'
# scopeHeader = <instrument> ('@' <number>)?
# playStmt = 'play'<note>(','<note>)*'for'<duration>';'
# waitStmt = 'wait''for'<duration>';'
# duration = <number>|<floating_number>
# note = <noteName>('#'|'_')?<number>
*/
//Start of Parser ---

program:
    instrumentBlock* EOF;

whiteSpace:
    SPACES* NEWLINE*;

instrumentBlock:
    whiteSpace scopeHeader whiteSpace OPENBLOCK whiteSpace
        (playStatement|waitStatement)*
    CLOSEBLOCK whiteSpace
    ;

scopeHeader:
    INSTRUMENT
        //set the instrument according to the text given
        { System.out.println("set Instrument to " + $INSTRUMENT.text); }
    (whiteSpace TEMPOMARKER whiteSpace NUMBER)?
        //if a tempo was included, set the value accordingly
        {
            if($NUMBER != null) {
                System.out.println("set tempo to " + $NUMBER.text);
            }
        }
    ;

playStatement:
    whiteSpace PLAY whiteSpace note (whiteSpace COMMA whiteSpace note)* whiteSpace FOR whiteSpace duration whiteSpace ENDSTMT whiteSpace
    {
        System.out.println(" play note(s) for duration: " + $duration.value);
    }
    ;


waitStatement:
    whiteSpace WAIT whiteSpace FOR whiteSpace duration whiteSpace ENDSTMT whiteSpace
    {
        System.out.println("wait for: " + $duration.value);
    }
    ;

duration
returns [long value]
:
    //placeholder function blocks used for now, before linking to the MIDIHelper
    NUMBER { $value = Long.valueOf($NUMBER.int); }
    | FLOAT { $value = (long)(Double.parseDouble($FLOAT.text)); }
    ;

note:
    NOTENAME whiteSpace NUMBER
    {
        String res = $NOTENAME.text;
        if($NOTENAME.text.contains("#")){
            //noted sharp
        }
        if($NOTENAME.text.contains("_")){
            //noted flat
        }

        res+= " num: " + $NUMBER.text + ", ";
        System.out.print(res);
    }
    ;



//LEXER section ---

NEWLINE : ('\r'? '\n')+ ;
SPACES : [ \t]+ ;

OPENBLOCK: '{';
CLOSEBLOCK: '}';
TEMPOMARKER: '@';
ENDSTMT: ';';
COMMA: ',';
FLOAT: [0-9]+'.'[0-9]+;
NUMBER: [0-9]+;
FOR: 'for';
PLAY: 'play';
WAIT: 'wait';
NOTENAME: [a-g]('#'|'_')?;
INSTRUMENT: [a-zA-Z]+;
