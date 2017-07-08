using AnirudhRb.USql;
using Antlr4.Runtime;
using Antlr4.Runtime.Misc;
using System;
using System.Text;

namespace USqlParserTests
{
    static class USqlScriptParseHelper
    {
        public static void Parse(string script, bool printTokens = false)
        {
            var input = new AntlrInputStream(script);
            var uSqlLexer = new USqlLexer(input);
            uSqlLexer.AddErrorListener(new LexerErrorListener());

            if (printTokens)
            {
                PrintTokens(uSqlLexer);
            }

            var tokens = new CommonTokenStream(uSqlLexer);
            var parser = new USqlParser(tokens) {ErrorHandler = new BailErrorStrategy()};
            parser.AddErrorListener(new ParserErrorListener());
            parser.AddParseListener(new FullListener());
            try
            {
                parser.prog();
            }
            catch (ParseCanceledException e)
            {
                var inputMismatchException = (InputMismatchException) e.InnerException;
                if (inputMismatchException != null)
                {
                    Console.WriteLine("Offending token: " + inputMismatchException.OffendingToken.Text, inputMismatchException);
                    throw inputMismatchException;
                }
                throw;
            }
        }

        private static void PrintTokens(ITokenSource tokenSource)
        {
            for (IToken token = tokenSource.NextToken(); token.Type != TokenConstants.Eof; token = tokenSource.NextToken())
            {
                Console.WriteLine(token.Text + " " + USqlLexer.DefaultVocabulary.GetSymbolicName(token.Type));
            }
        }
    }

    public class LexerErrorListener : IAntlrErrorListener<int>
    {
        public void SyntaxError(IRecognizer recognizer, int offendingSymbol, int line, int charPositionInLine, string msg, RecognitionException e)
        {
            Console.WriteLine("Error in parser at line {0}:{1}", line, charPositionInLine);
            Console.WriteLine("offender: " + e.OffendingToken.Text);
            throw new Exception("Parsing failed. " + e.Message);
        }
    }

    public class ParserErrorListener : IAntlrErrorListener<IToken>
    {
        public void SyntaxError(IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, string msg, RecognitionException e)
        {
            Console.WriteLine("Error in parser at line {0}:{1}", line, charPositionInLine);
            Console.WriteLine("offender. " + e.OffendingToken.Text);
            throw new Exception("Parsing failed. Reason: " + e.Message);
        }
    }

    public class FullListener : USqlParserBaseListener
    {
        public override void ExitUseDatabaseStatement([NotNull] USqlParser.UseDatabaseStatementContext context)
        {
            base.ExitUseDatabaseStatement(context);
            Console.WriteLine("USE statement. Changing database context to: {0}", context.dbName().GetText());
        }

        public override void ExitCreateSchemaStatement([NotNull] USqlParser.CreateSchemaStatementContext context)
        {
            base.ExitCreateSchemaStatement(context);
            Console.WriteLine("Create schema: {0}", context.quotedOrUnquotedIdentifier().GetText());
        }

        public override void ExitDropTableStatement([NotNull] USqlParser.DropTableStatementContext context)
        {
            base.ExitDropTableStatement(context);
            Console.WriteLine("Drop table {0} {1}", (context.IF() == null) ? "" : "IF EXISTS", context.multipartIdentifier().GetText());
        }

        public override void ExitCreateDatabaseStatement([NotNull] USqlParser.CreateDatabaseStatementContext context)
        {
            base.ExitCreateDatabaseStatement(context);
            if (context.exception != null)
            {
                Console.WriteLine("exception: " + context.exception.Message);
            }
            else
            {
                Console.WriteLine("Encountered Create Database statement for Db {0}", context.dbName().GetText());
            }
        }

        public override void ExitCreateManagedTableWithSchemaStatement([NotNull] USqlParser.CreateManagedTableWithSchemaStatementContext context)
        {
            base.ExitCreateManagedTableWithSchemaStatement(context);

            Console.WriteLine("Creating table: {0}", context.tableName().GetText());
            foreach (var columnDef in context.tableWithSchema().columnDefinition())
            {
                Console.WriteLine("    " + columnDef.quotedOrUnquotedIdentifier().GetText() + " " + columnDef.builtInType().GetText());
            }

            if (context.tableWithSchema().tableIndex() != null)
            {
                Console.Write("Index {0} on ", context.tableWithSchema().tableIndex().quotedOrUnquotedIdentifier().GetText());
                foreach (var x in context.tableWithSchema().tableIndex().sortItemList().sortItem())
                {
                    Console.Write("{0} {1} ", x.quotedOrUnquotedIdentifier().GetText(), (x.sortDirection() == null) ? "Default direction" : x.sortDirection().GetText());
                }
                Console.WriteLine();
            }

            if (context.tableWithSchema().partitionSpecification() != null)
            {
                Console.Write("Partitioned by: ");
                foreach (var x in context.tableWithSchema().partitionSpecification().identifierList().quotedOrUnquotedIdentifier())
                {
                    Console.Write("{0}, ", x.GetText());
                }
                Console.WriteLine("\b\b");
            }


            if (context.tableWithSchema().partitionSpecification() != null && context.tableWithSchema().partitionSpecification().distributionSpecification() != null)
            {
                Console.Write("Distributed by: ");
                foreach (var x in context.tableWithSchema().partitionSpecification().distributionSpecification().distributionScheme().identifierList().quotedOrUnquotedIdentifier())
                {
                    Console.Write("{0}, ", x.GetText());
                }
                Console.WriteLine("\b\b");
            }

            Console.WriteLine("Create table done");
        }

        public override void ExitAlterTableStatement([NotNull] USqlParser.AlterTableStatementContext context)
        {
            base.ExitAlterTableStatement(context);
            Console.WriteLine("Altering table: " + context.multipartIdentifier().GetText() + " 1: " + context.multipartIdentifier().quotedOrUnquotedIdentifier(2).GetText());
        }

        public override void ExitAlterTableAddDropPartitionStatement([NotNull] USqlParser.AlterTableAddDropPartitionStatementContext context)
        {
            base.ExitAlterTableAddDropPartitionStatement(context);
            Console.Write("Altering table with partition: " + context.multipartIdentifier().GetText());
            Console.Write("Operation: {0}. ", (context.ADD() == null) ? "DROP" : "ADD");
            Console.Write("Partitions: ");
            foreach (var partitionLabel in context.partitionLabelList().partitionLabel())
            {
                Console.Write("(");
                foreach (var staticExpression in partitionLabel.staticExpressionRowConstructor().staticExpressionList().staticExpression())
                {
                    Console.Write(staticExpression.GetText());
                }
                Console.Write(") ");
            }
            Console.WriteLine();
        }

        public override void ExitDeclareVariableStatement([NotNull] USqlParser.DeclareVariableStatementContext context)
        {
            base.ExitDeclareVariableStatement(context);
            Console.WriteLine("Declaring variable: " + context.variable().GetText());
        }

        public override void ExitInsertStatement([NotNull] USqlParser.InsertStatementContext context)
        {
            base.ExitInsertStatement(context);
            var valuesText = new StringBuilder();
            foreach (var expression in context.insertSource().tableValueConstructorExpression().rowConstructorList().rowConstructor(0).expressionList().expression())
            {
                valuesText.Append($" {expression.GetText()} ");
            }
            Console.WriteLine("Inserting into {0}, values {1}", context.multipartIdentifier().GetText(), valuesText);
        }

        public override void EnterMemberAccess(USqlParser.MemberAccessContext context)
        {
            base.EnterMemberAccess(context);
            Console.WriteLine("Entered memberAccess rule for: {0}", context.GetText());
        }

        public override void ExitPrimaryExpression(USqlParser.PrimaryExpressionContext context)
        {
            base.ExitPrimaryExpression(context);
            Console.WriteLine("Primary expression: {0}", context.GetText());
        }
    }
}
