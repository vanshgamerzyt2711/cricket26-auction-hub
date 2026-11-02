using Mono.Cecil;
using Mono.Cecil.Cil;

if (args.Length != 2) throw new ArgumentException("Usage: UiPolish <Cricket26AuctionManager.exe> <expected-old-version>");
string file = Path.GetFullPath(args[0]);
string oldVersion = args[1];
const string newVersion = "5.0.2";
if (oldVersion != "5.0.1") throw new InvalidOperationException("Only the verified 5.0.1 base is supported.");
if (!File.Exists(file)) throw new FileNotFoundException(file);

using var asm = AssemblyDefinition.ReadAssembly(file, new ReaderParameters { ReadingMode = ReadingMode.Immediate });
var module = asm.MainModule;
var typeManager = module.Types.Single(t => t.Name == "AuctionManager");
var typePages = module.Types.Single(t => t.Name == "HubPages");
var typeSurface = module.Types.Single(t => t.Name == "HubSurface");

if (asm.Name.Version != new Version(5, 0, 1, 0))
    throw new InvalidOperationException("Unexpected application assembly version.");

var doubleBufferRef = typeSurface.Methods.Single(m => m.IsConstructor && !m.IsStatic).Body.Instructions
    .Select(i => i.Operand as MethodReference)
    .FirstOrDefault(m => m?.Name == "set_DoubleBuffered")
    ?? throw new InvalidOperationException("Unable to locate verified double-buffer WinForms method.");
Console.WriteLine("Found UI double-buffer call: " + doubleBufferRef.FullName);

// Apply root-form double buffering once after controls have been constructed.
var managerCtor = typeManager.Methods.Single(m => m.IsConstructor && !m.IsStatic);
var ctorReturns = managerCtor.Body.Instructions.Where(i => i.OpCode == OpCodes.Ret).ToArray();
if (ctorReturns.Length != 1) throw new InvalidOperationException("Unexpected main form initialization shape.");
var ci = managerCtor.Body.GetILProcessor();
foreach (var ret in ctorReturns)
{
    ci.InsertBefore(ret, Instruction.Create(OpCodes.Ldarg_0));
    ci.InsertBefore(ret, Instruction.Create(OpCodes.Ldc_I4_1));
    ci.InsertBefore(ret, Instruction.Create(OpCodes.Call, doubleBufferRef));
}
Console.WriteLine("Enabled double-buffer painting for main window.");

// WinForms native Panels/ListViews do not enable double buffering by default.
// Create derived drop-in controls with only a one-time painting optimization.
TypeDefinition BuildSmoothControl(string name, TypeReference baseType, MethodReference baseConstructor)
{
    var newType = new TypeDefinition("", name,
        Mono.Cecil.TypeAttributes.Public | Mono.Cecil.TypeAttributes.Class | Mono.Cecil.TypeAttributes.Sealed,
        baseType);
    module.Types.Add(newType);
    var ctor = new MethodDefinition(".ctor",
        Mono.Cecil.MethodAttributes.Public | Mono.Cecil.MethodAttributes.HideBySig |
        Mono.Cecil.MethodAttributes.SpecialName | Mono.Cecil.MethodAttributes.RTSpecialName,
        module.TypeSystem.Void);
    newType.Methods.Add(ctor);
    var il = ctor.Body.GetILProcessor();
    il.Append(Instruction.Create(OpCodes.Ldarg_0));
    il.Append(Instruction.Create(OpCodes.Call, baseConstructor));
    il.Append(Instruction.Create(OpCodes.Ldarg_0));
    il.Append(Instruction.Create(OpCodes.Ldc_I4_1));
    il.Append(Instruction.Create(OpCodes.Call, doubleBufferRef));
    il.Append(Instruction.Create(OpCodes.Ret));
    return newType;
}

int ReplaceConstructor(MethodDefinition target, string baseFullName, string derivedName)
{
    var all = target.Body.Instructions.Where(i => i.OpCode == OpCodes.Newobj
        && i.Operand is MethodReference m && m.DeclaringType.FullName == baseFullName).ToArray();
    if (all.Length == 0) throw new InvalidOperationException($"No expected {baseFullName} in {target.Name}.");
    var original = (MethodReference)all[0].Operand;
    var subtype = BuildSmoothControl(derivedName, original.DeclaringType, original);
    var derivedConstructor = subtype.Methods.Single(m => m.IsConstructor);
    foreach (var item in all) item.Operand = derivedConstructor;
    return all.Length;
}

var pageFactory = typeManager.Methods.Single(m => m.Name == "Page");
var listFactory = typeManager.Methods.Single(m => m.Name == "List");
int countPage = ReplaceConstructor(pageFactory, "System.Windows.Forms.Panel", "HubSmoothPage");
int countList = ReplaceConstructor(listFactory, "System.Windows.Forms.ListView", "HubSmoothListView");
int countFlow = ReplaceConstructor(managerCtor, "System.Windows.Forms.FlowLayoutPanel", "HubSmoothFlowPanel");
Console.WriteLine($"Buffered controls: {countPage} page factory, {countList} list factory, {countFlow} flow panels.");

// Old tab switch rendered TWO full-size DrawToBitmap screenshots for every navigation.
// Replace that expensive animation with an equivalent instant show/hide + BringToFront.
// Keeps selected page state and ClearTransition cleanup, without allocating large bitmaps.
var setter = typePages.Methods.Single(m => m.Name == "set_SelectedIndex");
var old = setter.Body.Instructions.ToArray();
MethodReference FindCall(string name)
{
    return old.Select(i => i.Operand as MethodReference).FirstOrDefault(m => m?.Name == name)
           ?? throw new InvalidOperationException("Expected original UI call missing: " + name);
}
var countRef = FindCall("get_Count");
var indexRef = FindCall("get_Item");
var visibleRef = FindCall("set_Visible");
var frontRef = FindCall("BringToFront");
var pagesField = typePages.Fields.Single(f => f.Name == "pages");
var selectedField = typePages.Fields.Single(f => f.Name == "selected");
var clear = typePages.Methods.Single(m => m.Name == "ClearTransition");

setter.Body.ExceptionHandlers.Clear();
setter.Body.Variables.Clear();
setter.Body.Instructions.Clear();
setter.Body.InitLocals = true;
setter.Body.MaxStackSize = 8;
setter.Body.Variables.Add(new VariableDefinition(module.TypeSystem.Int32));
var ilSet = setter.Body.GetILProcessor();
void Emit(OpCode op) => ilSet.Append(Instruction.Create(op));
void Emit(OpCode op, int val) => ilSet.Append(Instruction.Create(op, val));
void Emit(OpCode op, FieldReference fld) => ilSet.Append(Instruction.Create(op, fld));
void Emit(OpCode op, MethodReference method) => ilSet.Append(Instruction.Create(op, method));
void Emit(OpCode op, Instruction target) => ilSet.Append(Instruction.Create(op, target));

var loop = Instruction.Create(OpCodes.Ldloc_0);
var done = Instruction.Create(OpCodes.Ldarg_0);
var ret = Instruction.Create(OpCodes.Ret);
// if (value < 0 || value >= pages.Count || value == selected) return
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Ldc_I4_0);
Emit(OpCodes.Blt, ret);
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Ldfld, pagesField);
Emit(OpCodes.Callvirt, countRef);
Emit(OpCodes.Bge, ret);
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Ldfld, selectedField);
Emit(OpCodes.Beq, ret);
// ClearTransition(); selected = value;
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Call, clear);
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Stfld, selectedField);
Emit(OpCodes.Ldc_I4_0);
Emit(OpCodes.Stloc_0);
// for each page: page.Visible = i == value;
ilSet.Append(loop);
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Ldfld, pagesField);
Emit(OpCodes.Callvirt, countRef);
Emit(OpCodes.Bge, done);
Emit(OpCodes.Ldarg_0);
Emit(OpCodes.Ldfld, pagesField);
Emit(OpCodes.Ldloc_0);
Emit(OpCodes.Callvirt, indexRef);
Emit(OpCodes.Ldloc_0);
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Ceq);
Emit(OpCodes.Callvirt, visibleRef);
Emit(OpCodes.Ldloc_0);
Emit(OpCodes.Ldc_I4_1);
Emit(OpCodes.Add);
Emit(OpCodes.Stloc_0);
Emit(OpCodes.Br, loop);
// pages[value].BringToFront();
ilSet.Append(done);
Emit(OpCodes.Ldfld, pagesField);
Emit(OpCodes.Ldarg_1);
Emit(OpCodes.Callvirt, indexRef);
Emit(OpCodes.Callvirt, frontRef);
ilSet.Append(ret);
Console.WriteLine("Page-switch animation replaced with non-allocating navigation.");

// Version metadata, updater comparison strings and visible title must match.
int constants = 0, literalStrings = 0, titleStrings = 0;
static IEnumerable<TypeDefinition> AllTypes(IEnumerable<TypeDefinition> types)
{
    foreach (var t in types) {
        yield return t;
        foreach (var inner in AllTypes(t.NestedTypes)) yield return inner;
    }
}
foreach (var t in AllTypes(module.Types))
{
    foreach (var field in t.Fields)
        if (field.HasConstant && field.Constant is string val && val == oldVersion) {
            field.Constant = newVersion;
            constants++;
        }
    foreach (var method in t.Methods) {
        if (!method.HasBody) continue;
        foreach (var inst in method.Body.Instructions) {
            if (inst.OpCode != OpCodes.Ldstr || inst.Operand is not string current) continue;
            if (current.Contains(oldVersion, StringComparison.Ordinal)) {
                inst.Operand = current.Replace(oldVersion, newVersion, StringComparison.Ordinal);
                literalStrings++;
            }
            if (current == "Cricket 26 Auction Hub | V4") {
                inst.Operand = "Cricket 26 Auction Hub | V5.0.2 UI Preview";
                titleStrings++;
            }
        }
    }
}
foreach (var attr in asm.CustomAttributes)
{
    if (attr.AttributeType.Name is "AssemblyFileVersionAttribute" or "AssemblyInformationalVersionAttribute"
        && attr.ConstructorArguments.Count == 1 && attr.ConstructorArguments[0].Value is string oldAttribute
        && oldAttribute.Contains(oldVersion, StringComparison.Ordinal))
    {
        attr.ConstructorArguments[0] = new CustomAttributeArgument(module.TypeSystem.String, oldAttribute.Replace(oldVersion, newVersion, StringComparison.Ordinal));
    }
}
if (literalStrings < 2 || constants < 1 || titleStrings != 1)
    throw new InvalidOperationException($"Unexpected version strings. Literal={literalStrings}; constant={constants}; title={titleStrings}.");
asm.Name.Version = new Version(5, 0, 2, 0);
var temporary = file + ".ui-patched";
asm.Write(temporary);
asm.Dispose();
File.SetAttributes(file, FileAttributes.Normal);
File.Move(temporary, file, true);
using var check = AssemblyDefinition.ReadAssembly(file);
if (check.Name.Version != new Version(5, 0, 2, 0)
    || check.MainModule.Types.Count(t => t.Name.StartsWith("HubSmooth", StringComparison.Ordinal)) != 3)
    throw new InvalidOperationException("Final patched-assembly validation failed.");
Console.WriteLine($"UI patch successful. Assembly {check.Name.Version}, updater strings {literalStrings}, constants {constants}.");