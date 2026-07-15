using System.Net;
using System.Text.Json;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.Exceptions;

namespace PhoneStore.API.Middlewares;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger, IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (AIProviderException ex)
        {
            _logger.LogWarning(ex, "AI provider request failed.");
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = ex.StatusCode;

            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            var json = JsonSerializer.Serialize(ApiResponse.ErrorResponse(ex.Message), options);

            await context.Response.WriteAsync(json);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, ex.Message);
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

            var response = _env.IsDevelopment()
                ? ApiResponse.ErrorResponse(ex.Message, new List<string> { ex.StackTrace?.ToString() ?? "" })
                : ApiResponse.ErrorResponse(ex.Message);

            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            var json = JsonSerializer.Serialize(response, options);

            await context.Response.WriteAsync(json);
        }
    }
}
