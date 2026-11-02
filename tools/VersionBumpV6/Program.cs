using Mono.Cecil;
using Mono.Cecil.Cil;

if (args.Length != 2)
    throw new ArgumentException("Usage: VersionBumpV6 <main EXE> <6.0.0>");
string path = Path.GetFullPath(args[0]);
string requested = args[1];
const string original = "5.0.3";
const string next = "6.0.0";
if (requested != next) throw new InvalidOperationException("Only reviewed V6 release version is allowed.");
if (!File.Exists(path)) throw new FileNotFoundException("Main EXE missing", path);

using var asm = AssemblyDefinition.ReadAssembly(path, new ReaderParameters { ReadingMode = ReadingMode.Immediate });
if (asm.Name.Name != "Cricket26AuctionManager" || asm.Name.Version != new Version(5,0,3,0))
    throw new InvalidOperationException("Unexpected base assembly; requires verified V5.0.3.");

static IEnumerable<TypeDefinition> Walk(IEnumerable<TypeDefinition> types)
{
    foreach(var t in types) {
        yield return t;
        foreach(var inner in Walk(t.NestedTypes)) yield return inner;
    }
}

int literals = 0, constants = 0;
foreach(var type in Walk(asm.MainModule.Types)) {
    foreach(var field in type.Fields) {
        if (field.HasConstant && field.Constant is string value && value.Contains(original, StringComparison.Ordinal)) {
            field.Constant = value.Replace(original, next, StringComparison.Ordinal);
            constants++;
        }
    }
    foreach(var method in type.Methods) {
        if (!method.HasBody) continue;
        foreach(var instruction in method.Body.Instructions) {
            if (instruction.OpCode == OpCodes.Ldstr && instruction.Operand is string text && text.Contains(original, StringComparison.Ordinal)) {
                instruction.Operand = text.Replace(original, next, StringComparison.Ordinal);
                literals++;
            }
        }
    }
}
foreach(var attribute in asm.CustomAttributes) {
    if (attribute.AttributeType.FullName is "System.Reflection.AssemblyInformationalVersionAttribute" or "System.Reflection.AssemblyFileVersionAttribute"
        && attribute.ConstructorArguments.Count == 1
        && attribute.ConstructorArguments[0].Value is string versionText
        && versionText.Contains(original, StringComparison.Ordinal)) {
            attribute.ConstructorArguments[0] = new CustomAttributeArgument(
                asm.MainModule.TypeSystem.String,
                versionText.Replace(original, next, StringComparison.Ordinal));
    }
}
if (literals < 2 || constants < 1)
    throw new InvalidOperationException($"Unexpected version references: literals={literals}, constants={constants}");
asm.Name.Version = new Version(6,0,0,0);
var temp = path + ".patched-v6";
asm.Write(temp);
asm.Dispose();
File.SetAttributes(path, FileAttributes.Normal);
File.Move(temp, path, true);

using var check = AssemblyDefinition.ReadAssembly(path);
if (check.Name.Version != new Version(6,0,0,0))
    throw new InvalidOperationException("V6 assembly verification failed");
if (Walk(check.MainModule.Types).SelectMany(t => t.Methods)
    .Where(m => m.HasBody).SelectMany(m => m.Body.Instructions)
    .Any(i => i.OpCode == OpCodes.Ldstr && i.Operand is string s && s == original))
    throw new InvalidOperationException("Old version literals remain in V6 main binary");
Console.WriteLine($"V6 update package main EXE ready; replaced {literals} references and {constants} constants.");
