using System.Collections.Generic;

namespace PhoneStore.Application.Interfaces.AI;

public interface IToolRegistry
{
    IEnumerable<IAITool> GetToolsForRole(string role);
    IAITool? GetToolByName(string name);
}
