%{
import java.io.*;
import javax.xml.parsers.*;
import org.xml.sax.*;
import java.util.regex.*;
%}

%token NL WS TAG_OPEN TAG_CLOSE TAG_END_OPEN TAG_NC EQUAL DOCTYPE XML_VERSION	/*dico quali sono i simboli terminali*/
%token<sval> TAG_NAME ATT_NAME ATT_VALUE CONTENT			/*dico quali sono i simobli terminali di tipo stringa*/

%type<sval> group element root end content atts att indent line wss	/*dico quali siano i simboli non terminali di tipo stringa*/

%%

/* vado a definire le varie produzioni */

json		: group 							{println($1);}
			;
			
group		: indent element 			                    {$$ = $2;}
			| indent TAG_OPEN DOCTYPE TAG_CLOSE group		{$$ = $5;}
			| TAG_OPEN XML_VERSION TAG_CLOSE group		    {$$ = $4;}
			;
			
element		: TAG_OPEN TAG_NAME wss atts TAG_NC line wss      { $$ = "{\n\t\"tag\" :"  + "\"" + $2 + "\"" + "\n" + $4 + "\n}";}
			| root line wss content end			            { $$ = $1 + "\t\"content\": [" + $4 + "]\n\t" + $5 + "\n";}
			;

root		: TAG_OPEN TAG_NAME wss atts TAG_CLOSE          { $$ = "{\n\t\"tag\": " + "\"" + $2 + "\"" + ",\n" + $4; }
			;

end 		: TAG_END_OPEN TAG_NAME wss TAG_CLOSE line      { $$ = "\n\t}";}
			;
			
content		: CONTENT content				{
												Pattern pattern = Pattern.compile("[\r\t\n]+");
												Matcher matcher = pattern.matcher($1);
												if(matcher.matches()){
													$$ = $2;
												} else {
													$$ = "\"" + $1 + "\"" + $2;
												}
											;}
			| element content		{$$ = $1 + $2;}
			| /*no content*/				{$$ = "";}
			;
			
atts		: att               						{$$ = $1;}
			| att WS atts                               {$$ = $1 + $3;}
            | /*no attribute*/							{$$ = "";}
			;

att         : ATT_NAME EQUAL ATT_VALUE			        {$$ = "\t\"@" + $1 + "\": " + $3 + ",\n";}
            ;
			
indent		: NL 		 			{$$ = System.lineSeparator();}
			| WS 					{$$ = "";}
			| NL WS					{$$ = System.lineSeparator();}
			;

line		: /* no NL*/			{$$ = "";}
			| NL					{$$ = System.lineSeparator();}
			;
			
wss			: /*no wss*/		{$$ = "";}
			| WS				{$$ = "";}
			;

%%

private Yylex lexer;

/* definisco il metodo yylex che è usato dal parser per ottenere i token identificati dal lexer */

private int yylex () {

	int yyl_return = -1;
	try {
		yyval = new ParserVal(0);
		yyl_return = lexer.yylex();
	}
	catch (IOException e) {
		System.err.println("IO error :" +e);
	}
	return yyl_return;
}


/*gestione degli errori*/

public void yyerror(String error) {
	System.err.println("Error: " + error);
}

/*stampa i risultati*/

public void println(String str){
	Writer writer = null;
	try{
		str = str.replaceAll("}[\\n\\t]?\"","},\"");
		str = str.replaceAll("\"\\{","\",{");
		str = str.replaceAll("\\}[\\t\\n]?\\{","},{");
		writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("outputJSON.txt"), "utf-8"));
		writer.write(str);
	} catch (IOException ex) { }
	finally {
		try{writer.close();}
		catch(Exception ex) {}
	}
}

public Parser(Reader r) {
	lexer = new Yylex(r, this);
}

public static void main(String[] args) throws FileNotFoundException{
	if(args.length == 0){
		System.out.println("Inserire il file da processare.");
	} else if(Parser.isXmlValid(args[0])){
		Parser yyparser = new Parser(new FileReader(args[0]));
		yyparser.yyparse();
	}
}

private static boolean isXmlValid(String file){
	DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
	factory.setValidating(true);
	factory.setNamespaceAware(true);

	DocumentBuilder builder;
	try {
		builder = factory.newDocumentBuilder();
	} catch (ParserConfigurationException e1) {
		System.out.println("Errore durante la generazione del DocumentBuilder.");
		return false;
	}
	
	builder.setErrorHandler(new ErrorHandler() {
		@Override
		public void warning(SAXParseException exception) throws SAXException {
			throw exception;
		}
		
		@Override
		public void fatalError(SAXParseException exception) throws SAXException {
			throw exception;
		}
		
		@Override
		public void error(SAXParseException exception) throws SAXException {
			throw exception;
		}
	});
	
	boolean isValid = true;
	
	try {
		builder.parse(new InputSource(file));
	} catch (SAXException e) {
		System.out.println("File xml non valido. " + e.getMessage());
		isValid = false;
	} catch (IOException e) {
		System.out.println("File non trovato: " + e.getMessage());
		isValid = false;
	}
	
	return isValid;
}