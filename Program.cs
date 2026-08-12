using DbUp;
using System.Reflection;

string connectionString = args.FirstOrDefault()
    ?? "Server=192.168.11.85;Database=csquickshipmerged_db;User Id=csquickshipmerged_db;Password=csquickshipm@!32233;TrustServerCertificate=True;MultipleActiveResultSets=True;";

Console.WriteLine("==========================================");
Console.WriteLine(" DbUp Migration Tool Runner");
Console.WriteLine(" Strategy: Additive-Only Database Migrations");
Console.WriteLine("==========================================");
Console.WriteLine($"Target Connection: {connectionString}");

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