grammar MIDee;

//Included in the generated .java file above the class definition
@header {
package cas.cs4tb3.parser;
import java.util.*;
import cas.cs4tb3.MIDIHelper;
}

//Included in the body of the generated class. This is the place
//to define fields, method, nested classes etc.
@members {

    public List notesToPlay = new ArrayList();
    private MIDIHelper midi = new MIDIHelper();

    public String currentInstrument = "";
    public int currentTempo = 120;
    public long currentTick = 0;

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
    instrumentBlock*
    {
        midi.saveSequence();
    }
    EOF;

whiteSpace:
    SPACES* NEWLINE*;

instrumentBlock:
    whiteSpace scopeHeader whiteSpace OPENBLOCK whiteSpace
        (playStatement|waitStatement)*
    CLOSEBLOCK whiteSpace
;

scopeHeader:
    INSTRUMENT
        //set the instrument according to the text given, if it is different from the current instrument
        {
            if(!$INSTRUMENT.text.equals(currentInstrument)){
                int instrmnt = midi.getInstrumentId($INSTRUMENT.text);
                if(instrmnt == -1){
                    //error... no instrument found
                }
                //set instrument
                else{
                    midi.setInstrument(instrmnt, currentTick);
                    currentInstrument = $INSTRUMENT.text;
                }
            }
        }
    (whiteSpace TEMPOMARKER whiteSpace NUMBER)?
        //if a tempo was included, set the value accordingly, only if it is different from the current tempo. same goes for when tempo is excluded
        {
            if($NUMBER != null) {
                if($NUMBER.int != currentTempo){
                    midi.setTempo($NUMBER.int, currentTick);
                    currentTempo = $NUMBER.int;
                }
            }
            else{
                if(currentTempo != 120){
                    midi.setTempo(120, currentTick);
                    currentTempo = 120;
                }
            }
        }
;

playStatement:
    whiteSpace PLAY whiteSpace note (whiteSpace COMMA whiteSpace note)* whiteSpace FOR whiteSpace duration whiteSpace ENDSTMT whiteSpace
    {
        //schedule the note(s) to play from current tie till the given duration
        if(notesToPlay.size() > 1){
            for(Object singleNote:notesToPlay){
                midi.play((Integer)singleNote, currentTick, currentTick+$duration.value);
            }
        }
        else{
            midi.play((Integer)notesToPlay.get(0), currentTick, currentTick+$duration.value);
        }

        //now update the tick and clear the notesToPlay array
        currentTick += $duration.value;
        notesToPlay.clear();
    }
;


waitStatement:
    whiteSpace WAIT whiteSpace FOR whiteSpace duration whiteSpace ENDSTMT whiteSpace
    {
        currentTick += $duration.value;
    }
;

duration
returns [long value]
:
    //convert beats into ticks and store the value
    NUMBER
        {
            $value = midi.getDurationInTicks((double)$NUMBER.int);
        }
    | FLOAT
        {
            $value = midi.getDurationInTicks(Double.parseDouble($FLOAT.text));
        }
;

note:
    NOTENAME whiteSpace NUMBER
    {
        //converting a name [a-g] (#|_) with an octave number (0-10) into int
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
INSTRUMENT: ([a-zA-Z]+);
