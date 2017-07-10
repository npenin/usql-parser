using System;
using System.IO;
using System.Reflection;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace USqlParserTests
{
    [TestClass]
    public class USqlGrammarTest
    {
        [TestMethod]
        public void TestAllSamples()
        {
            var binariesDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().GetName().CodeBase);
            if (binariesDirectory != null && binariesDirectory.StartsWith(@"file:\"))
            {
                binariesDirectory = binariesDirectory.Substring(6);
            }
            else if (binariesDirectory == null)
            {
                Assert.Fail("Binaries directory is null");
            }

            var samplesDirectory = Path.Combine(binariesDirectory, "USqlSamples");

            foreach (var file in Directory.EnumerateFiles(samplesDirectory, "*.usql"))
            {
                Console.WriteLine(file);
                var script = File.ReadAllText(file);
                USqlScriptParseHelper.Parse(script);
            }

            Assert.IsNull(null);
        }

        [TestMethod]
        [Ignore]
        public void TestSingleFile()
        {
            var script = File.ReadAllText(@"C:\Users\anrayabh\Source\Repos\USqlParser\USqlParserTests\bin\Debug\USqlSamples\Sample.usql");
            USqlScriptParseHelper.Parse(script, false);

            Assert.IsNull(null);
        }
    }
}
