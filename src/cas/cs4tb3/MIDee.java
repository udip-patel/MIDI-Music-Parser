package cas.cs4tb3;

import cas.cs4tb3.parser.MIDeeLexer;
import cas.cs4tb3.parser.MIDeeParser;
import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;

import java.io.IOException;

public class MIDee {

    public static void main(String[] args) throws IOException {
        ANTLRInputStream input = new ANTLRInputStream(System.in);
        MIDeeLexer lexer = new MIDeeLexer(input);

        CommonTokenStream tokens = new CommonTokenStream(lexer);
        MIDeeParser parser = new MIDeeParser(tokens);

        try {
            parser.program();
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }
}
