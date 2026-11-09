using System.Reflection;
using System.Runtime.InteropServices.JavaScript;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

// Einstiegspunkt der WebAssembly-App. Die eigentliche Arbeit macht
// Runner.Run, das von JavaScript (main.js) aufgerufen wird.
Console.WriteLine("C#-Laufzeit bereit.");

public static partial class Runner
{
    // Entspricht den impliziten usings einer normalen .NET-Konsolen-App.
    const string GlobalUsings =
        "global using System;\n" +
        "global using System.Collections.Generic;\n" +
        "global using System.IO;\n" +
        "global using System.Linq;\n" +
        "global using System.Threading;\n" +
        "global using System.Threading.Tasks;\n";

    static List<MetadataReference>? references;
    static SyntaxTree? usingsTree;
    static readonly CSharpParseOptions ParseOptions = new(LanguageVersion.Latest);

    /// <summary>
    /// Kompiliert <paramref name="code"/> (Top-Level-Statements erlaubt),
    /// führt ihn mit <paramref name="stdin"/> als Eingabe aus und liefert
    /// JSON: { "stdout": ..., "stderr": ..., "error": ... | null }.
    /// </summary>
    [JSExport]
    public static string Run(string code, string stdin)
    {
        references ??= Basic.Reference.Assemblies.Net80.References.All
            .Cast<MetadataReference>()
            .ToList();
        usingsTree ??= CSharpSyntaxTree.ParseText(GlobalUsings, ParseOptions, "Usings.cs", Encoding.UTF8);

        var tree = CSharpSyntaxTree.ParseText(code, ParseOptions, "Program.cs", Encoding.UTF8);
        var compilation = CSharpCompilation.Create(
            "DeinProgramm",
            new[] { tree, usingsTree },
            references,
            new CSharpCompilationOptions(
                OutputKind.ConsoleApplication,
                nullableContextOptions: NullableContextOptions.Disable,
                concurrentBuild: false,
                optimizationLevel: OptimizationLevel.Release));

        using var ms = new MemoryStream();
        using var pdb = new MemoryStream();
        var emit = compilation.Emit(ms, pdb, options: new Microsoft.CodeAnalysis.Emit.EmitOptions(
            debugInformationFormat: Microsoft.CodeAnalysis.Emit.DebugInformationFormat.PortablePdb));
        if (!emit.Success)
        {
            var errors = emit.Diagnostics
                .Where(d => d.Severity == DiagnosticSeverity.Error)
                .Take(8)
                .Select(d =>
                {
                    var line = d.Location.GetLineSpan().StartLinePosition.Line + 1;
                    return $"Zeile {line}: {d.Id} {d.GetMessage()}";
                });
            return Json("", "", "Kompilierfehler:\n" + string.Join("\n", errors));
        }

        var assembly = Assembly.Load(ms.ToArray(), pdb.ToArray());
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        var oldOut = Console.Out;
        var oldErr = Console.Error;
        var oldIn = Console.In;
        string? error = null;
        try
        {
            Console.SetOut(stdout);
            Console.SetError(stderr);
            Console.SetIn(new StringReader(stdin));
            var entry = assembly.EntryPoint!;
            var args = entry.GetParameters().Length == 0
                ? null
                : new object[] { Array.Empty<string>() };
            var result = entry.Invoke(null, args);
            if (result is Task task) task.GetAwaiter().GetResult();
        }
        catch (TargetInvocationException e) when (e.InnerException != null)
        {
            error = Describe(e.InnerException);
        }
        catch (Exception e)
        {
            error = Describe(e);
        }
        finally
        {
            Console.SetOut(oldOut);
            Console.SetError(oldErr);
            Console.SetIn(oldIn);
        }
        return Json(stdout.ToString(), stderr.ToString(), error);
    }

    static string? Describe(Exception e)
    {
        // Die Robotersimulation beendet ein Programm mit RobotFehler – das
        // Ereignis wurde schon ausgegeben, also ist das kein Absturz.
        if (e.GetType().Name == "RobotFehler") return null;
        var line = "";
        var trace = e.StackTrace ?? "";
        var idx = trace.IndexOf("Program.cs:line ", StringComparison.Ordinal);
        if (idx >= 0)
        {
            var digits = new string(trace.Skip(idx + 16).TakeWhile(char.IsDigit).ToArray());
            if (digits.Length > 0) line = $"Zeile {digits}: ";
        }
        return $"Laufzeitfehler – {line}{e.GetType().Name}: {e.Message}";
    }

    static string Json(string stdout, string stderr, string? error)
    {
        var sb = new StringBuilder("{");
        sb.Append("\"stdout\":").Append(Escape(stdout)).Append(',');
        sb.Append("\"stderr\":").Append(Escape(stderr)).Append(',');
        sb.Append("\"error\":").Append(error == null ? "null" : Escape(error));
        return sb.Append('}').ToString();
    }

    static string Escape(string s)
    {
        var sb = new StringBuilder("\"");
        foreach (var c in s)
        {
            switch (c)
            {
                case '"': sb.Append("\\\""); break;
                case '\\': sb.Append("\\\\"); break;
                case '\n': sb.Append("\\n"); break;
                case '\r': sb.Append("\\r"); break;
                case '\t': sb.Append("\\t"); break;
                default:
                    if (c < 0x20) sb.Append($"\\u{(int)c:x4}");
                    else sb.Append(c);
                    break;
            }
        }
        return sb.Append('"').ToString();
    }
}
