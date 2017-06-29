 grammar USql;


/*
 * Parser rules
 */

prog
	: createDatabaseStatement prog
	| createManagedTableWithSchemaStatement prog
	| alterTableStatement prog
	| alterTableAddDropPartitionStatement prog
	| dropTableStatement prog
	| createSchemaStatement prog
	| declareVariableStatement prog
	| useDatabaseStatement prog
	| insertStatement prog
    | EOF
	;

createDatabaseStatement
	: CREATE DATABASE ( IF NOT EXISTS )? dbName ';'
	;

dbName
	: quotedOrUnquotedIdentifier
	;

unquotedIdentifier
	: ID
	;

quotedIdentifier
	: '[' unquotedIdentifier ']'
	;

quotedOrUnquotedIdentifier
	: quotedIdentifier
	| unquotedIdentifier
	;

multipartIdentifier
	: quotedOrUnquotedIdentifier
	| quotedOrUnquotedIdentifier '.' quotedOrUnquotedIdentifier
	| quotedOrUnquotedIdentifier '.' quotedOrUnquotedIdentifier '.' quotedOrUnquotedIdentifier
	;

useDatabaseStatement
	: 'USE' DATABASE dbName ';'
	;

numericType
	: NumericTypeNonNullable
	| NumericTypeNonNullable '?'
	;

simpleType
	: numericType
	| TextualType
	| TemporalType
	| OtherType
	;

builtInType
	: simpleType
	;

createSchemaStatement
	: CREATE SCHEMA ( IF NOT EXISTS )? quotedOrUnquotedIdentifier ';'
	;

columnDefinition
	: quotedOrUnquotedIdentifier builtInType
	;

tableWithSchema
	: ( '(' ( columnDefinition ',' )*
		( tableIndex partitionSpecification )?
		  ( ',' columnDefinition )* ')' )
	| ( '(' ( columnDefinition ',' )*
		( tableIndex )
			( ',' columnDefinition )* ')' partitionSpecification )
	;

tableName
	: multipartIdentifier
	;

createManagedTableWithSchemaStatement
	: CREATE TABLE ( IF NOT EXISTS )? tableName tableWithSchema ';'
	;

sortDirection
	: 'ASC' | 'DESC'
	;

sortItem
	: quotedOrUnquotedIdentifier ( sortDirection )?
	;

sortItemList
	: sortItem ( ',' sortItem )*
	;

tableIndex
	: INDEX quotedOrUnquotedIdentifier CLUSTERED '(' sortItemList ')'
	;

identifierList
	: quotedOrUnquotedIdentifier ( ',' quotedOrUnquotedIdentifier )*
	;

distributionScheme
	: 'RANGE' '(' sortItemList ')'
	| 'HASH' '(' identifierList ')'
	| 'DIRECT' 'HASH' '(' quotedOrUnquotedIdentifier ')'
	| 'ROUND' 'ROBIN'
	;

distributionSpecification
	: 'DISTRIBUTED' ( 'BY' )? distributionScheme
	;

partitionSpecification
	: ( 'PARTITIONED' ( 'BY' )? '(' identifierList ')' )? distributionSpecification
	;

columnDefinitionList
	: '(' columnDefinition ( ',' columnDefinition )* ')'
	;

alterTableStatement
	: 'ALTER' 'TABLE' multipartIdentifier
	  ( 'REBUILD' 
	  | ADD 'COLUMN' columnDefinitionList
	  | DROP 'COLUMN' identifierList ) ';'
	;

systemVariable
	: '@@' unquotedIdentifier
	;

userVariable
	: '@' unquotedIdentifier
	;

variable
	: systemVariable
	| userVariable
	;

declareVariableStatement
	: 'DECLARE' variable builtInType '=' ~( ';' )* ';'
	; 

/*
 * TODO: Include StaticVariable and BinaryLiteral. Need to figure it out.
 */
staticExpression
	: StringLiteral
	| CharLiteral
	| NumberLiteral
	| userVariable
	;

staticExpressionList
	: staticExpression ( ',' staticExpression )*
	;

staticExpressionRowConstructor
	: '(' staticExpressionList ')'
	;

partitionLabel
	: 'PARTITION' staticExpressionRowConstructor
	;

partitionLabelList
	: partitionLabel ( ',' partitionLabel )*
	;

alterTableAddDropPartitionStatement
	: 'ALTER' 'TABLE' multipartIdentifier
	   ( ADD ( IF NOT EXISTS )? | DROP ( IF NOT EXISTS )? ) partitionLabelList ';'
	;

dropTableStatement
	: DROP TABLE ( IF EXISTS )? multipartIdentifier ';'
	;

integrityViolationAction
	: 'IGNORE'
	| 'MOVE' 'TO' partitionLabel
	;

integrityClause
	: 'ON' 'INTEGRITY' 'VIOLATION' integrityViolationAction
	;

rowConstructorList
	: '(' ~( ',' )* ( ',' ~( ',' )* )* ')'
	;

tableValueConstructorExpression
	: 'VALUES' rowConstructorList
	;

insertSource
	: tableValueConstructorExpression
	;

insertStatement
	: 'INSERT' 'INTO' multipartIdentifier ( '(' identifierList ')' )?
	  ( partitionLabel | integrityClause )? insertSource ';'
	;

/*
 * Lexer rules
 * TODO: make upper case
 */

CREATE
	: 'create' | 'CREATE'
	;

DATABASE
	: 'database' | 'DATABASE'
	;

SCHEMA
	: 'SCHEMA'
	;

TABLE
	: 'TABLE'
	;

INDEX
	: 'INDEX'
	;

CLUSTERED
	: 'CLUSTERED'
	;

IF
	: 'if' | 'IF'
	;

NOT
	: 'not' | 'NOT'
	;

EXISTS
	: 'exists' | 'EXISTS'
	;

ADD
	: 'ADD'
	;

DROP
	: 'DROP'
	;

NumericTypeNonNullable
	: 'byte' | 'sbyte' | 'int' | 'uint' | 'long' | 'ulong' | 'float' | 'double' | 'decimal' | 'short' | 'ushort'
	;

TextualType
	: 'char' | 'char?' | 'string'
	;

TemporalType
	: 'DateTime' | 'DateTime?'
	;

OtherType
	: 'bool' | 'bool?' | 'Guid' | 'Guid?' | 'byte[]'
	;

CharLiteral
	: '\'' . '\''
	;

StringLiteral
	: '"' ( 'a' .. 'z' | 'A' .. 'Z' | '_' )+ '"'
	;

/*
 * TODO: Improve the number literal rule to include floats, hex, octal, long etc. More research needed.
 */
NumberLiteral
	: ( '0' .. '9' )+
	;

NEWLINE
   : '\r'? '\n' -> skip
   ;

WS
   : ( ' ' | '\t' | '\n' | '\r' )+ -> skip
   ;

ID
   : ( 'a' .. 'z' | 'A' .. 'Z' | '_' )+
   ;