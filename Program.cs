using DbUp;
using System.Reflection;

string connectionString = args.FirstOrDefault(a => !a.StartsWith("--"))
    ?? "Server=(localdb)\\mssqllocaldb;Database=DbUpTestDb;Trusted_Connection=True;MultipleActiveResultSets=true";

bool checkOnly = args.Contains("--check-connection-only");

Console.WriteLine("==========================================");
Console.WriteLine(" DbUp Migration Tool Runner");
Console.WriteLine(" Strategy: Additive-Only Database Migrations");
Console.WriteLine("==========================================");
Console.WriteLine($"Target Connection: {connectionString}");

if (checkOnly)
{
    Console.WriteLine("Mode: Target Database Connection Pre-Check Only");
    try
    {
        EnsureDatabase.For.SqlDatabase(connectionString);
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("Target database connection & credentials verified successfully!");
        Console.ResetColor();
        return 0;
    }
    catch (Exception ex)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine("Target database connection pre-check failed!");
        Console.WriteLine(ex.Message);
        Console.ResetColor();
        return -1;
    }
}

// Ensure target database exists before attempting migration
EnsureDatabase.For.SqlDatabase(connectionString);

var upgrader = DeployChanges.To
    .SqlDatabase(connectionString)
    .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
    .LogToConsole()
    .Build();

var result = upgrader.PerformUpgrade();

if (!result.Successful)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("Migration failed!");
    Console.WriteLine(result.Error);
    Console.ResetColor();
    return -1;
}

Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine("Database migration completed successfully!");
Console.ResetColor();
return 0;