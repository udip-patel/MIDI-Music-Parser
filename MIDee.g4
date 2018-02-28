grammar MIDee;

//Included in the generated .java file above the class definition
@header {
package cas.cs4tb3.parser;
import java.util.*;
}

//Included in the body of the generated class. This is the place
//to define fields, method, nested classes etc.
@members {

    public List notesToPlay = new ArrayList();

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
        String noteArray = "";
        if(notesToPlay.size() > 1){
            for(Object singleNote:notesToPlay){
                noteArray+= String.valueOf(singleNote) + " ";
            }
        }
        else noteArray = String.valueOf(notesToPlay.get(0));

        System.out.println(" notes to play: " + noteArray);
        System.out.println(" play note(s) for duration: " + $duration.value);
        notesToPlay.clear();
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
        //converting a name [a-g] (#|_) with an octave number into an MIDI int
        int res = 0;
        String currentNote = $NOTENAME.text;

        //match the note with its base octave at 0 (from the MIDI table)
        //https://midikits.net/midi_analyser/midi_note_numbers_for_octaves.htm
        if(currentNote.contains("c")) res = 0;
        else if(currentNote.contains("d")) res = 2;
        else if(currentNote.contains("e")) res = 4;
        else if(currentNote.contains("f")) res = 5;
        else if(currentNote.contains("g")) res = 7;
        else if(currentNote.contains("a")) res = 9;
        else if(currentNote.contains("b")) res = 11;
        else{
            //signal error... cannot play this note
        }

        //sharp or flat increments/decrements a semitone
        if($NOTENAME.text.contains("#")) res++;
        if($NOTENAME.text.contains("_")) res--;

        //add 12 times the octave number to the result, this is the note to play
        res += 12*$NUMBER.int;

        //keep value within MIDI note boundaries
        if(res < 0) res = 0;
        if(res > 127) res = 127;

        notesToPlay.add(res);
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
