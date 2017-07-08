parser grammar USqlParser;

options { tokenVocab=USqlLexer; }

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
	: CREATE DATABASE ( IF NOT EXISTS )? dbName SEMICOLON
	;

dbName
	: quotedOrUnquotedIdentifier
	;

quotedOrUnquotedIdentifier
	: QuotedIdentifier
	| UnquotedIdentifier
	;

multipartIdentifier
	: quotedOrUnquotedIdentifier
	| quotedOrUnquotedIdentifier DOT quotedOrUnquotedIdentifier
	| quotedOrUnquotedIdentifier DOT quotedOrUnquotedIdentifier DOT quotedOrUnquotedIdentifier
	;

useDatabaseStatement
	: USE DATABASE dbName SEMICOLON
	;

numericType
	: NumericTypeNonNullable
	| NumericTypeNonNullable QUESTIONMARK
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
	: CREATE SCHEMA ( IF NOT EXISTS )? quotedOrUnquotedIdentifier SEMICOLON
	;

columnDefinition
	: quotedOrUnquotedIdentifier builtInType
	;

tableWithSchema
	: ( LPAREN columnDefinition ( COMMA columnDefinition )*
		( COMMA tableIndex partitionSpecification )?
		  ( COMMA columnDefinition )* RPAREN )
	| ( LPAREN ( columnDefinition COMMA )*
		( tableIndex )
			( COMMA columnDefinition )* RPAREN partitionSpecification )
	;

tableName
	: multipartIdentifier
	;

createManagedTableWithSchemaStatement
	: CREATE TABLE ( IF NOT EXISTS )? tableName tableWithSchema SEMICOLON
	;

sortDirection
	: ASC | DESC
	;

sortItem
	: quotedOrUnquotedIdentifier ( sortDirection )?
	;

sortItemList
	: sortItem ( COMMA sortItem )*
	;

tableIndex
	: INDEX quotedOrUnquotedIdentifier CLUSTERED LPAREN sortItemList RPAREN
	;

identifierList
	: quotedOrUnquotedIdentifier ( COMMA quotedOrUnquotedIdentifier )*
	;

distributionScheme
	: RANGE LPAREN sortItemList RPAREN
	| HASH LPAREN identifierList RPAREN
	| DIRECT HASH LPAREN quotedOrUnquotedIdentifier RPAREN
	| ROUND ROBIN
	;

distributionSpecification
	: DISTRIBUTED ( BY )? distributionScheme
	;

partitionSpecification
	: ( PARTITIONED ( BY )? LPAREN identifierList RPAREN )? distributionSpecification
	;

columnDefinitionList
	: LPAREN columnDefinition ( COMMA columnDefinition )* RPAREN
	;

alterTableStatement
	: ALTER TABLE multipartIdentifier
	  ( REBUILD 
	  | ADD COLUMN columnDefinitionList
	  | DROP COLUMN identifierList ) SEMICOLON
	;

variable
	: SystemVariable
	| UserVariable
	;

declareVariableStatement
	: DECLARE variable builtInType EQUALS ~( SEMICOLON )* SEMICOLON
	; 

staticVariable
	: builtInType DOT UnquotedIdentifier 
	;

/*
 * TODO: Include StaticVariable and BinaryLiteral. Need to figure it out.
 */
staticExpression
	: StringLiteral
	| CharLiteral
	| IntegerLiteral
	| RealLiteral
	| UserVariable
	| staticVariable
	;

staticExpressionList
	: staticExpression ( COMMA staticExpression )*
	;

staticExpressionRowConstructor
	: LPAREN staticExpressionList RPAREN
	;

partitionLabel
	: PARTITION staticExpressionRowConstructor
	;

partitionLabelList
	: partitionLabel ( COMMA partitionLabel )*
	;

alterTableAddDropPartitionStatement
	: ALTER TABLE multipartIdentifier
	   ( ADD ( IF NOT EXISTS )? | DROP ( IF NOT EXISTS )? ) partitionLabelList SEMICOLON
	;

dropTableStatement
	: DROP TABLE ( IF EXISTS )? multipartIdentifier SEMICOLON
	;

integrityViolationAction
	: IGNORE
	| MOVE TO partitionLabel
	;

integrityClause
	: ON INTEGRITY VIOLATION integrityViolationAction
	;

expression
	: variable
	| ( LPAREN builtInType RPAREN )? literal
	;

expressionList
	: expression ( COMMA expression )*
	;

rowConstructor
	: LPAREN expressionList RPAREN
	;

rowConstructorList
	:  rowConstructor ( COMMA rowConstructor )*
	;

tableValueConstructorExpression
	: VALUES rowConstructorList
	;

insertSource
	: tableValueConstructorExpression
	;

insertStatement
	: INSERT INTO multipartIdentifier ( LPAREN identifierList RPAREN )?
	  ( partitionLabel | integrityClause )? insertSource SEMICOLON
	;

literal
	: StringLiteral
	| IntegerLiteral
	| RealLiteral
	| BooleanLiteral
	| CharLiteral
	| NullLiteral
	;
