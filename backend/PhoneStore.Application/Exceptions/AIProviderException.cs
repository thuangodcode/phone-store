namespace PhoneStore.Application.Exceptions;

public sealed class AIProviderException : Exception
{
    public AIProviderException(string message, int statusCode)
        : base(message)
    {
        StatusCode = statusCode;
    }

    public int StatusCode { get; }
}
