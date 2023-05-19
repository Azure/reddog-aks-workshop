FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /App

RUN dotnet new console -n keyvault-console-app
WORKDIR /App/keyvault-console-app
RUN dotnet add package Azure.Security.KeyVault.Secrets
RUN dotnet add package Azure.Identity

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /App
COPY --from=build-env /App/keyvault-console-app/out .
ENTRYPOINT ["dotnet", "keyvault-console-app.dll"]
