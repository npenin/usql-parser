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
            if (binariesDirectory.StartsWith(@"file:\"))
            {
                binariesDirectory = binariesDirectory.Substring(6);
            }

            var samplesDirectory = Path.Combine(binariesDirectory, "USqlSamples");

            foreach (var file in Directory.EnumerateFiles(samplesDirectory, "*.usql"))
            {
                Console.WriteLine(file);
                var script = File.ReadAllText(file);
                new USqlScriptParseHelper().Parse(script);
            }

            Assert.IsNull(null);
        }
    }
}
