using System;
using System.Linq;
using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;
using PhoneStore.Infrastructure.AI.Prompts;

namespace PhoneStore.Infrastructure.AI.Agent;

public class AIAgentService : IAIAgentService
{
    private readonly IAIProvider _aiProvider;
    private readonly IAIMemoryService _memoryService;
    private readonly IToolRegistry _toolRegistry;
    private readonly IAILogService _logService;

    public AIAgentService(IAIProvider aiProvider, IAIMemoryService memoryService, IToolRegistry toolRegistry, IAILogService logService)
    {
        _aiProvider = aiProvider;
        _memoryService = memoryService;
        _toolRegistry = toolRegistry;
        _logService = logService;
    }

    public async Task<AIChatResponseDto> ProcessChatAsync(AIChatRequestDto request, string userId, string role)
    {
        var sessionId = request.SessionId;
        if (string.IsNullOrEmpty(sessionId))
        {
            sessionId = Guid.NewGuid().ToString();
        }

        // 1. Save user message to memory
        var userMsg = new ChatMessageDto { Role = "user", Content = request.Message };
        await _memoryService.AddMessageAsync(sessionId, userMsg);

        // 2. Retrieve history and inject system prompt based on role
        var history = await _memoryService.GetHistoryAsync(sessionId);
        var systemPrompt = SystemPromptFactory.GetPromptForRole(role);
        
        var conversation = history.ToList();
        conversation.Insert(0, new ChatMessageDto { Role = "system", Content = systemPrompt });

        // 3. Get authorized tools
        var availableTools = _toolRegistry.GetToolsForRole(role);

        await _logService.LogSessionEventAsync(sessionId, userId, role, new Domain.Entities.AILogEvent
        {
            EventType = "PROMPT_COMPILED",
            Description = $"Compiled prompt with {conversation.Count} messages and {availableTools.Count()} tools.",
            RawData = System.Text.Json.JsonSerializer.Serialize(new { HistoryCount = conversation.Count, Role = role }),
            LatencyMs = 0
        });

        // 4. Interaction Loop (Handle Tool Calls)
        var maxIterations = 5;
        for (int i = 0; i < maxIterations; i++)
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var responseMsg = await _aiProvider.GenerateResponseAsync(conversation, availableTools);
            sw.Stop();

            await _logService.LogSessionEventAsync(sessionId, userId, role, new Domain.Entities.AILogEvent
            {
                EventType = "LLM_RESPONSE",
                Description = string.IsNullOrEmpty(responseMsg.ToolName) ? "Text Response" : $"Tool Call: {responseMsg.ToolName}",
                RawData = System.Text.Json.JsonSerializer.Serialize(responseMsg),
                LatencyMs = sw.ElapsedMilliseconds
            });

            if (!string.IsNullOrEmpty(responseMsg.ToolName))
            {
                // The AI decided to call a tool
                var tool = availableTools.FirstOrDefault(t => t.Name == responseMsg.ToolName);
                if (tool != null)
                {
                    // Execute tool
                    var toolSw = System.Diagnostics.Stopwatch.StartNew();
                    var toolResultContent = await tool.ExecuteAsync(responseMsg.Content);
                    toolSw.Stop();

                    await _logService.LogSessionEventAsync(sessionId, userId, role, new Domain.Entities.AILogEvent
                    {
                        EventType = "TOOL_EXECUTION",
                        Description = $"Executed tool: {tool.Name}",
                        RawData = System.Text.Json.JsonSerializer.Serialize(new { Arguments = responseMsg.Content, Result = toolResultContent }),
                        LatencyMs = toolSw.ElapsedMilliseconds
                    });
                    
                    // Add tool execution record to memory so it knows the result
                    var toolResponseMsg = new ChatMessageDto 
                    { 
                        Role = "tool", 
                        ToolName = tool.Name, 
                        ToolCallId = responseMsg.ToolCallId,
                        Content = toolResultContent 
                    };
                    
                    conversation.Add(responseMsg); // Add the function call 
                    conversation.Add(toolResponseMsg); // Add the function result
                    
                    await _memoryService.AddMessageAsync(sessionId, responseMsg);
                    await _memoryService.AddMessageAsync(sessionId, toolResponseMsg);
                    
                    // Loop back to LLM with the result
                    continue; 
                }
                else
                {
                    // Fallback if tool hallucinated or unauthorized
                    responseMsg.Content = "Tool not found or not authorized.";
                }
            }

            // Final text response
            await _memoryService.AddMessageAsync(sessionId, responseMsg);
            return new AIChatResponseDto 
            { 
                Response = responseMsg.Content, 
                SessionId = sessionId 
            };
        }

        return new AIChatResponseDto 
        { 
            Response = "Error: Tool execution loop limit exceeded.", 
            SessionId = sessionId 
        };
    }
}
