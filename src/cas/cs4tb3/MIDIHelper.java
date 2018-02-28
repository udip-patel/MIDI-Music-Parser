package cas.cs4tb3;

import javax.sound.midi.*;
import java.io.IOException;

public class MIDIHelper {
    private static final byte TIME_SIGNATURE_MIDI_SUBTYPE = 0x58;
    private static final byte TEMPO_MIDI_SUBTYPE = 0x51;

    private static final int MICROSECONDS_PER_MINUTE = 60000000;
    private static final byte TICKS_PER_METER_CLICK = 24;
    private static final byte THIRTY_SECOND_NOTES_PER_QUARTER = 8;
    private static final int DEFAULT_PPQN = 960;
    private static final int DEFUALT_VELOCITY = 96;

    private static final class ImmutableEndOfTrack extends MetaMessage {
        private static final byte EOT_EVENT_CODE = 0x2F;

        private ImmutableEndOfTrack() {
            super(new byte[3]);
            data[0] = (byte) META;
            data[1] = EOT_EVENT_CODE;
            data[2] = 0;
        }

        public void setMessage(int type, byte[] data, int length) throws InvalidMidiDataException {
            throw new InvalidMidiDataException("Cannot modify end of track message");
        }
    }

    private Sequence sequence;
    private Track mainTrack;

    public MIDIHelper() {
        try {
            sequence = new Sequence(Sequence.PPQ, DEFAULT_PPQN);
            mainTrack = sequence.createTrack();
        } catch (InvalidMidiDataException ignored) { /* its all hardcoded */ }

        MetaMessage timeSigMessage = null;
        try {
            timeSigMessage = new MetaMessage(TIME_SIGNATURE_MIDI_SUBTYPE, new byte[]{
                    4, 2,
                    TICKS_PER_METER_CLICK,
                    THIRTY_SECOND_NOTES_PER_QUARTER
            }, 4);
        } catch (InvalidMidiDataException ignored) { /* all hardcoded */ }

        mainTrack.add(new MidiEvent(timeSigMessage, 0));
        setTempo(120, 0);
    }

    /**
     * Set the tempo in beats per minute
     *
     * @param tempo the tempo in bpm. 120 is standard
     */
    public void setTempo(int tempo, long time) {
        int microSecPerBeat = MICROSECONDS_PER_MINUTE / tempo;
        MetaMessage tempoMessage = null;
        try {
            tempoMessage = new MetaMessage(TEMPO_MIDI_SUBTYPE, new byte[]{
                    (byte) ((microSecPerBeat >>> 16) & 0xFF),
                    (byte) ((microSecPerBeat >>> 8) & 0xFF),
                    (byte) ((microSecPerBeat) & 0xFF)
            }, 3);
        } catch (InvalidMidiDataException ignored) {
        }

        this.mainTrack.add(new MidiEvent(tempoMessage, time));
    }

    /**
     * Calculate the duration (state time ticks) of the given number
     * of beats.
     *
     * @param beats the number of beats
     *
     * @return the duration of {@code beats} in ticks
     */
    public long getDurationInTicks(double beats) {
        return (long) (beats * DEFAULT_PPQN);
    }

    /**
     * Change the instrument being used during the performance.
     *
     * @param instrument the name of the instrument
     * @param time       the state time at which the change should occur
     */
    public void setInstrument(int instrument, long time) {
        ShortMessage instrumentChange;
        try {
            instrumentChange = new ShortMessage(ShortMessage.PROGRAM_CHANGE, 0, instrument, 0);
        } catch (InvalidMidiDataException e) {
            throw new RuntimeException("MIDI Exception: Setting instrument to " + instrument + ".", e);
        }

        mainTrack.add(new MidiEvent(instrumentChange, time));
    }

    /**
     * Lookup an instrument by name.
     * @param name the name of the instrument
     * @return the midi number for the instrument or {@code -1} if
     *         the name is unknown.
     */
    public int getInstrumentId(String name) {
        GeneralMidiInstrument instrument = GeneralMidiInstrument.lookup(name);
        if (instrument == null) return -1;

        return instrument.midiNum();
    }

    /**
     * Play a single note
     *
     * @param note    the MIDI number of the note in range (0, 127)
     * @param timeon  the time (in ticks) that the note performance should start
     * @param timeoff the time (in ticks) that the note performance should end
     *
     * @see #getDurationOfBeat(double)
     */
    public void play(int note, long timeon, long timeoff) {
        ShortMessage noteOn;
        ShortMessage noteOff;

        try {
            noteOn = new ShortMessage(ShortMessage.NOTE_ON, 0, note, DEFUALT_VELOCITY);
        } catch (InvalidMidiDataException e) {
            throw new RuntimeException("MIDI Exception: Cannot turn note on (" + note + ")", e);
        }
        try {
            noteOff = new ShortMessage(ShortMessage.NOTE_OFF, 0, note, DEFUALT_VELOCITY);
        } catch (InvalidMidiDataException e) {
            throw new RuntimeException("MIDI Exception: Cannot turn note off (" + note + ")", e);
        }

        mainTrack.add(new MidiEvent(noteOn, timeon));
        mainTrack.add(new MidiEvent(noteOff, timeoff));
    }

    /**
     * Save the built up sequence to the given output stream. Should only be called <strong>once</strong>
     * upon completion of compilation.
     */
    public void saveSequence() {
        MidiEvent last = mainTrack.get(mainTrack.size() - 1);
        MidiEvent eot = new MidiEvent(new ImmutableEndOfTrack(), last.getTick() + DEFAULT_PPQN);
        mainTrack.add(eot);

        try {
            MidiSystem.write(this.sequence, 1, System.out);
        } catch (IOException e) {
            throw new RuntimeException("Error saving midi sequence. " + e.getMessage(), e);
        }
    }
}
