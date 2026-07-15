using System.Threading.Tasks;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAITool
{
    string Name { get; }
    string Description { get; }
    
    /// <summary>
    /// A JSON schema describing the parameters this tool accepts.
    /// </summary>
    string ParametersSchema { get; }
    
    Task<string> ExecuteAsync(string arguments);
}
