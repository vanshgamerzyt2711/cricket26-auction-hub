using Mono.Cecil;
using Mono.Cecil.Cil;

if (args.Length != 2)
    throw new ArgumentException("Usage: UpdateRepair <Cricket26AuctionManager.exe> <target version>");
var mainPath = Path.GetFullPath(args[0]);
var target = args[1];
if (target != "5.0.3") throw new ArgumentException("Only approved v5.0.3 patch is supported.");
var helperPath = Path.Combine(Path.GetDirectoryName(mainPath)!, "AuctionUpdateHelper.exe");
if (!File.Exists(helperPath) || !File.Exists(mainPath))
    throw new FileNotFoundException("Expected source binaries are missing.");

static IEnumerable<TypeDefinition> AllTypes(IEnumerable<TypeDefinition> types)
{
    foreach (var t in types) {
        yield return t;
        foreach (var nested in AllTypes(t.NestedTypes)) yield return nested;
    }
}

// Patch compiled main window without disturbing its tested v5.0.2 UI improvement.
using (var assembly = AssemblyDefinition.ReadAssembly(mainPath, new ReaderParameters { ReadingMode = ReadingMode.Immediate }))
{
    if (assembly.Name.Name != "Cricket26AuctionManager" || assembly.Name.Version != new Version(5, 0, 2, 0))
        throw new InvalidOperationException("Expected verified v5.0.2 source main assembly.");
    int strings = 0, constants = 0;
    foreach (var type in AllTypes(assembly.MainModule.Types)) {
        foreach (var field in type.Fields) {
            if (field.HasConstant && field.Constant is string s && s.Contains("5.0.2", StringComparison.Ordinal)) {
                field.Constant = s.Replace("5.0.2", target, StringComparison.Ordinal);
                constants++;
            }
        }
        foreach (var method in type.Methods) {
            if (!method.HasBody) continue;
            foreach (var inst in method.Body.Instructions) {
                if (inst.OpCode == OpCodes.Ldstr && inst.Operand is string s && s.Contains("5.0.2", StringComparison.Ordinal)) {
                    inst.Operand = s.Replace("5.0.2", target, StringComparison.Ordinal).Replace("UI Preview", "Smooth UI", StringComparison.Ordinal);
                    strings++;
                }
            }
        }
    }
    foreach (var attr in assembly.CustomAttributes) {
        if (attr.AttributeType.Name is "AssemblyInformationalVersionAttribute" or "AssemblyFileVersionAttribute"
            && attr.ConstructorArguments.Count == 1 && attr.ConstructorArguments[0].Value is string s
            && s.Contains("5.0.2", StringComparison.Ordinal)) {
            attr.ConstructorArguments[0] = new CustomAttributeArgument(assembly.MainModule.TypeSystem.String, s.Replace("5.0.2", target, StringComparison.Ordinal));
        }
    }
    if (strings < 2 || constants < 1)
        throw new InvalidOperationException($"Unexpected main binary version patch count: strings={strings}, constants={constants}.");
    assembly.Name.Version = new Version(5, 0, 3, 0);
    var temp = mainPath + ".fixed";
    assembly.Write(temp);
    assembly.Dispose();
    File.SetAttributes(mainPath, FileAttributes.Normal);
    File.Move(temp, mainPath, true);
    Console.WriteLine($"Main app version set to v{target}; strings={strings}; constants={constants}");
}

// Preserve the original anti-symlink checks, and allow ONLY the two official locations.
// Legacy: %LOCALAPPDATA%\Cricket26AuctionHub\App
// Modern Inno installer: %LOCALAPPDATA%\Programs\Cricket26AuctionHub
using (var assembly = AssemblyDefinition.ReadAssembly(helperPath, new ReaderParameters { ReadingMode = ReadingMode.Immediate }))
{
    var module = assembly.MainModule;
    var method = AllTypes(module.Types).SelectMany(t => t.Methods)
        .Single(m => m.Name == "ValidateInstallRoot" && m.IsStatic
                     && m.Parameters.Count == 1 && m.Parameters[0].ParameterType.FullName == "System.String");

    if (!method.HasBody || method.Body.Instructions.All(i => i.Operand is not string s || s != "Setup can only update its own installed app folder"))
        throw new InvalidOperationException("Original safety guard not found, refusing to patch.");

    MethodReference Find(string declaringType, string name, int argc) =>
        method.Body.Instructions.Select(i => i.Operand as MethodReference)
            .FirstOrDefault(m => m?.DeclaringType.FullName == declaringType && m.Name == name && m.Parameters.Count == argc)
        ?? throw new InvalidOperationException($"Safety guard method missing: {declaringType}.{name}/{argc}");

    var folder = Find("System.Environment", "GetFolderPath", 1);
    var combine = Find("System.IO.Path", "Combine", 3);
    var fullPath = Find("System.IO.Path", "GetFullPath", 1);
    var trim = Find("System.String", "TrimEnd", 1);
    var equals = Find("System.String", "Equals", 2);
    var empty = Find("System.String", "IsNullOrEmpty", 1);
    var exists = Find("System.IO.Directory", "Exists", 1);
    var attributes = Find("System.IO.File", "GetAttributes", 1);
    var parent = Find("System.IO.Path", "GetDirectoryName", 1);
    var exceptionCtor = Find("System.Exception", ".ctor", 1);

    method.Body.ExceptionHandlers.Clear();
    method.Body.Instructions.Clear();
    method.Body.Variables.Clear();
    method.Body.InitLocals = true;
    method.Body.MaxStackSize = 12;
    // local0=normalized actual path, local1=legacy approved path, local2=modern approved path,
    // local3=security traversal cursor
    for (int k=0; k<4; k++) method.Body.Variables.Add(new VariableDefinition(module.TypeSystem.String));
    var il = method.Body.GetILProcessor();

    // Normalize actual root (including a trailing directory separator).
    il.Emit(OpCodes.Ldarg_0);
    il.Emit(OpCodes.Call, fullPath);
    il.Emit(OpCodes.Ldc_I4_1);
    il.Emit(OpCodes.Newarr, module.TypeSystem.Char);
    il.Emit(OpCodes.Dup);
    il.Emit(OpCodes.Ldc_I4_0);
    il.Emit(OpCodes.Ldc_I4_S, (sbyte)92); // Windows directory separator (constant in .NET Framework IL)
    il.Emit(OpCodes.Stelem_I2);
    il.Emit(OpCodes.Callvirt, trim);
    il.Emit(OpCodes.Stloc_0);

    // Path.GetFullPath(Path.Combine(Environment.GetFolderPath(LocalApplicationData), part1, part2))
    void ApprovedPath(string part1, string part2, int destination)
    {
        il.Emit(OpCodes.Ldc_I4_S, (sbyte)28); // Environment.SpecialFolder.LocalApplicationData
        il.Emit(OpCodes.Call, folder);
        il.Emit(OpCodes.Ldstr, part1);
        il.Emit(OpCodes.Ldstr, part2);
        il.Emit(OpCodes.Call, combine);
        il.Emit(OpCodes.Call, fullPath);
        il.Emit(destination == 1 ? OpCodes.Stloc_1 : OpCodes.Stloc_2);
    }
    ApprovedPath("Cricket26AuctionHub", "App", 1);
    ApprovedPath("Programs", "Cricket26AuctionHub", 2);

    // if (actual.Equals(legacy, OrdinalIgnoreCase) || actual.Equals(modern, OrdinalIgnoreCase))
    var approved = Instruction.Create(OpCodes.Nop);
    il.Emit(OpCodes.Ldloc_0);
    il.Emit(OpCodes.Ldloc_1);
    il.Emit(OpCodes.Ldc_I4_5); // StringComparison.OrdinalIgnoreCase
    il.Emit(OpCodes.Callvirt, equals);
    il.Emit(OpCodes.Brtrue, approved);
    il.Emit(OpCodes.Ldloc_0);
    il.Emit(OpCodes.Ldloc_2);
    il.Emit(OpCodes.Ldc_I4_5);
    il.Emit(OpCodes.Callvirt, equals);
    il.Emit(OpCodes.Brtrue, approved);

    il.Emit(OpCodes.Ldstr, "Setup can only update its own installed app folder");
    il.Emit(OpCodes.Newobj, exceptionCtor);
    il.Emit(OpCodes.Throw);

    il.Append(approved);
    il.Emit(OpCodes.Ldloc_0);
    il.Emit(OpCodes.Stloc_3);
    var loop = Instruction.Create(OpCodes.Nop);
    var end = Instruction.Create(OpCodes.Ret);
    var next = Instruction.Create(OpCodes.Nop);
    il.Append(loop);

    il.Emit(OpCodes.Ldloc_3);
    il.Emit(OpCodes.Call, empty);
    il.Emit(OpCodes.Brtrue, end);

    // Reject reparse points at the install directory or any parent.
    il.Emit(OpCodes.Ldloc_3);
    il.Emit(OpCodes.Call, exists);
    il.Emit(OpCodes.Brfalse, next);
    il.Emit(OpCodes.Ldloc_3);
    il.Emit(OpCodes.Call, attributes);
    il.Emit(OpCodes.Ldc_I4, 0x400); // FileAttributes.ReparsePoint
    il.Emit(OpCodes.And);
    il.Emit(OpCodes.Brfalse, next);

    il.Emit(OpCodes.Ldstr, "Linked installation folders are unsupported");
    il.Emit(OpCodes.Newobj, exceptionCtor);
    il.Emit(OpCodes.Throw);

    il.Append(next);
    il.Emit(OpCodes.Ldloc_3);
    il.Emit(OpCodes.Call, parent);
    il.Emit(OpCodes.Stloc_3);
    il.Emit(OpCodes.Br, loop);
    il.Append(end);

    string temp = helperPath + ".fixed";
    assembly.Write(temp);
    assembly.Dispose();
    File.SetAttributes(helperPath, FileAttributes.Normal);
    File.Move(temp, helperPath, true);
    Console.WriteLine("Updated helper validates both known official install roots while rejecting linked directories.");
}

using (var main = AssemblyDefinition.ReadAssembly(mainPath))
    if (main.Name.Version != new Version(5,0,3,0))
        throw new InvalidOperationException("Main output version validation failed.");
using (var helper = AssemblyDefinition.ReadAssembly(helperPath)) {
    var validate = AllTypes(helper.MainModule.Types).SelectMany(t=>t.Methods)
        .Single(m=>m.Name == "ValidateInstallRoot");
    if (validate.Body.Instructions.Count < 45 || validate.Body.Instructions.All(i=>i.Operand is not string s||s!="Linked installation folders are unsupported"))
        throw new InvalidOperationException("Updater helper guard was not preserved.");
}
Console.WriteLine("PASS: V5.0.3 binary validation and secure updater helper validation.");