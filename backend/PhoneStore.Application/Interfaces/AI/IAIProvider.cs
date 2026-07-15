using System.Collections.Generic;
using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAIProvider
{
    /// <summary>
    /// Generates a response from the AI provider given the conversation history and available tools.
    /// If the AI decides to call a tool, it returns a ChatMessageDto with ToolName and ToolCallId populated, and Role="tool_call" or "assistant".
    /// </summary>
    Task<ChatMessageDto> GenerateResponseAsync(List<ChatMessageDto> history, IEnumerable<IAITool> availableTools);
}
