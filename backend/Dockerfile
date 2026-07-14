# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files
COPY ["PhoneStore.sln", "./"]
COPY ["PhoneStore.API/PhoneStore.API.csproj", "PhoneStore.API/"]
COPY ["PhoneStore.Application/PhoneStore.Application.csproj", "PhoneStore.Application/"]
COPY ["PhoneStore.Domain/PhoneStore.Domain.csproj", "PhoneStore.Domain/"]
COPY ["PhoneStore.Infrastructure/PhoneStore.Infrastructure.csproj", "PhoneStore.Infrastructure/"]

# Restore dependencies
RUN dotnet restore

# Copy the rest of the source code
COPY . .

# Build and publish
WORKDIR "/src/PhoneStore.API"
RUN dotnet publish "PhoneStore.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Expose port (Render sets PORT environment variable, ASP.NET Core uses ASPNETCORE_URLS)
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "PhoneStore.API.dll"]
