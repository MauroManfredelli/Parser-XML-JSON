
%%

%byaccj

%x START INSIDE

%{
	private Parser yyparser;
	
	public Yylex(java.io.Reader r, Parser yyparser) {
		this(r);
		this.yyparser = yyparser;
	}

%}

DOCTYPE = \![a-zA-Z0-9.\' =\"-]+
XML_VERSION = \?[a-zA-Z0-9.\' =-]+\?
NL = \r\n | \r | \n
WS = [ \t]+
TAG_OPEN = "<"
TAG_NAME = [a-zA-Z0-9\-_]+
TAG_CLOSE = ">"
TAG_NC = "/>"
TAG_END_OPEN ="</"
ATT_NAME = [a-zA-Z0-9\-_]+
EQUAL = "="
ATT_VALUE = \"[a-zA-Z0-9\-_. ]*\"
CONTENT = [^<]*

%%

/*YYINITIAL è stato inclusivo*/
/*yybegin mi pone il lexer nello stato tra parentesi*/

<YYINITIAL>				{NL}			{return Parser.NL;}

<START>					{DOCTYPE}		{yybegin(INSIDE);
										return Parser.DOCTYPE;}

<START>					{XML_VERSION}	{yybegin(INSIDE);
										return Parser.XML_VERSION;}

<YYINITIAL, INSIDE>		{WS}			{return Parser.WS;}

<START>					{TAG_NAME}		{yyparser.yylval = new ParserVal(yytext());
										yybegin(INSIDE);
										return Parser.TAG_NAME;	}

<YYINITIAL>				{TAG_OPEN}		{yybegin(START);
										return Parser.TAG_OPEN; }

<YYINITIAL>				{CONTENT}		{yyparser.yylval = new ParserVal(yytext());
										 return Parser.CONTENT; }
									 
<INSIDE>				{TAG_CLOSE}		{yybegin(YYINITIAL);
										 return Parser.TAG_CLOSE;}
									 
<INSIDE>				{TAG_NC}		{yybegin(YYINITIAL);
										return Parser.TAG_NC;}
									 
<YYINITIAL> 			{TAG_END_OPEN}	{yybegin(START);
										 return Parser.TAG_END_OPEN;}
										 
<INSIDE>				{ATT_NAME}		{yyparser.yylval = new ParserVal(yytext());
										 return Parser.ATT_NAME; }

<INSIDE>				{ATT_VALUE}		{yyparser.yylval = new ParserVal(yytext());
										 yybegin(INSIDE);
										 return Parser.ATT_VALUE;}
										 
<INSIDE>				{EQUAL}			{return Parser.EQUAL;}