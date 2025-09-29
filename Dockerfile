# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
WORKDIR /src/ThroughputTest
RUN dotnet publish -c Release -f netcoreapp3.0 -r linux-x64 --self-contained false -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=build /app/publish .
COPY docker-entrypoint.sh .
ENTRYPOINT ["./docker-entrypoint.sh"]