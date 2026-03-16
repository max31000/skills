---
name: docker-helper
description: >
  Docker and container operations. Use when the user works with Docker,
  Dockerfile, docker-compose, containers, images, or mentions
  "docker", "container", "dockerfile", "compose", "image build".
---

# Docker Helper

Assist with Docker-related tasks: writing Dockerfiles, docker-compose configs,
debugging container issues, and optimizing images.

## Dockerfile Best Practices
- Use specific base image tags (not :latest).
- Order layers from least to most frequently changed.
- Combine RUN commands to reduce layers.
- Use multi-stage builds for compiled languages (C#, Go, Rust).
- Add .dockerignore to exclude build artifacts, node_modules, bin/obj.
- Run as non-root user in production images.
- Use COPY over ADD unless extracting archives.

## ASP.NET Core Specific
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
USER app
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

## React/Node Specific
```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

## Debugging Containers
- `docker logs <container>` — check output
- `docker exec -it <container> sh` — shell into running container
- `docker inspect <container>` — network, mounts, env
- `docker stats` — resource usage
- `docker system df` — disk usage
