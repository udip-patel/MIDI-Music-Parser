#MIDI Musical Notes/Duration Parser
\\
Uses ANTLR. to set up ANTLR on the terminal:\\
cd /usr/local/lib\\
$ wget http://www.antlr.org/download/antlr-4.7.1-complete.jar\\
$ export CLASSPATH=".:/usr/local/lib/antlr-4.7.1-complete.jar:$CLASSPATH"\\
$ alias antlr4='java -jar /usr/local/lib/antlr-4.7.1-complete.jar'\\
$ alias grun='java org.antlr.v4.gui.TestRig'\\

Then, to run this Parser:
antlr4 MIDIParser.g4 -no-listener\\
javac *.java\\
grun MIDIParser program "inputFile" > "outputFile"
//ex. grun ... sample.midee > out.txt

