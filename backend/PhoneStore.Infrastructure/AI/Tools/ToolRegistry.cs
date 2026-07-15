using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.DependencyInjection;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Tools;

public class ToolRegistry : IToolRegistry
{
    private readonly IServiceProvider _serviceProvider;
    private readonly List<Type> _allToolTypes;

    public ToolRegistry(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
        
        // In a real application, you might use Reflection to load all types implementing IAITool.
        _allToolTypes = new List<Type>
        {
            typeof(SearchProductsTool),
            typeof(GetRevenueAnalyticsTool)
        };
    }

    public IEnumerable<IAITool> GetToolsForRole(string role)
    {
        var tools = new List<IAITool>();
        var scope = _serviceProvider.CreateScope();
        
        foreach (var type in _allToolTypes)
        {
            if (scope.ServiceProvider.GetRequiredService(type) is IAITool tool)
            {
                // Simple RBAC logic for tools.
                // In a full implementation, you might map Tool Types to Roles in a dictionary.
                if (role.ToLower() == "admin")
                {
                    tools.Add(tool);
                }
                else if (role.ToLower() == "staff" && !tool.Name.Contains("Analytics", StringComparison.OrdinalIgnoreCase))
                {
                    tools.Add(tool);
                }
                else if ((role.ToLower() == "customer" || role.ToLower() == "guest") 
                         && tool.Name.Contains("Product", StringComparison.OrdinalIgnoreCase))
                {
                    tools.Add(tool);
                }
            }
        }

        return tools;
    }

    public IAITool? GetToolByName(string name)
    {
        var scope = _serviceProvider.CreateScope();
        foreach (var type in _allToolTypes)
        {
            if (scope.ServiceProvider.GetRequiredService(type) is IAITool tool && string.Equals(tool.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                return tool;
            }
        }
        return null;
    }
}
