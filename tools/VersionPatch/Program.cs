using Mono.Cecil;
using Mono.Cecil.Cil;

if (args.Length != 2)
    throw new ArgumentException("Usage: VersionPatch <Cricket26AuctionManager.exe> <newSemver>");

var path = Path.GetFullPath(args[0]);
const string oldVersion = "4.0.1";
var newVersion = args[1];
if (newVersion != "5.0.1")
    throw new ArgumentException("This migration is restricted to reviewed version 5.0.1.");
if (!File.Exists(path))
    throw new FileNotFoundException("Missing app binary", path);

using var assembly = AssemblyDefinition.ReadAssembly(path, new ReaderParameters { ReadingMode = ReadingMode.Immediate });
if (assembly.Name.Name != "Cricket26AuctionManager" || assembly.Name.Version.Major != 4)
    throw new InvalidOperationException("Unexpected input assembly. Refusing to rewrite it.");

var replacedStrings = 0;
var replacedConstants = 0;
var versionSuffixOld = oldVersion + ".0";
var versionSuffixNew = newVersion + ".0";

static IEnumerable<TypeDefinition> WalkTypes(IEnumerable<TypeDefinition> types)
{
    foreach (var type in types)
    {
        yield return type;
        foreach (var inner in WalkTypes(type.NestedTypes))
            yield return inner;
    }
}

foreach (var module in assembly.Modules)
{
    foreach (var type in WalkTypes(module.Types))
    {
        foreach (var field in type.Fields)
        {
            if (field.HasConstant && field.Constant is string val &&
                (val == oldVersion || val == versionSuffixOld))
            {
                field.Constant = val == oldVersion ? newVersion : versionSuffixNew;
                replacedConstants++;
            }
        }

        foreach (var method in type.Methods)
        {
            if (!method.HasBody) continue;
            foreach (var instruction in method.Body.Instructions)
            {
                if (instruction.OpCode != OpCodes.Ldstr || instruction.Operand is not string value)
                    continue;
                if (!value.Contains(oldVersion, StringComparison.Ordinal)) continue;
                instruction.Operand = value.Replace(oldVersion, newVersion, StringComparison.Ordinal);
                replacedStrings++;
            }
        }
    }
}

// The AssemblyFileVersion value is used by Windows Explorer and install diagnostics.
foreach (var attr in assembly.CustomAttributes)
{
    if (attr.AttributeType.FullName is "System.Reflection.AssemblyFileVersionAttribute" or
        "System.Reflection.AssemblyInformationalVersionAttribute")
    {
        if (attr.ConstructorArguments.Count == 1 && attr.ConstructorArguments[0].Value is string versionText &&
            versionText.Contains(oldVersion, StringComparison.Ordinal))
        {
            attr.ConstructorArguments[0] =
                new CustomAttributeArgument(assembly.MainModule.TypeSystem.String,
                    versionText.Replace(oldVersion, newVersion, StringComparison.Ordinal));
            replacedStrings++;
        }
    }
}

if (replacedStrings < 2 || replacedConstants < 1)
    throw new InvalidOperationException($"Unexpected source: {replacedStrings} string replacements, {replacedConstants} field constants. Refusing to write.");

assembly.Name.Version = new Version(5, 0, 1, 0);
var temp = path + ".patched";
assembly.Write(temp);
assembly.Dispose(); // Release Windows file handle before replacing the original assembly.
File.SetAttributes(path, FileAttributes.Normal);
File.Move(temp, path, true);
Console.WriteLine($"Updated {path}: {oldVersion} -> {newVersion}; strings={replacedStrings}, constants={replacedConstants}");

// Reopen and verify that the output is a valid managed assembly with the intended version.
using var verify = AssemblyDefinition.ReadAssembly(path);
if (verify.Name.Version != new Version(5, 0, 1, 0))
    throw new InvalidOperationException("Patched assembly version verification failed.");
