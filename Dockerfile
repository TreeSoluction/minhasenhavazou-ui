# 1️⃣ Build stage
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files first
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy project files
COPY . .

# Build for production
RUN yarn build


# 2️⃣ Runtime stage (Node-only)
FROM node:22-alpine

WORKDIR /app

# Copy only necessary files
COPY package.json yarn.lock ./

# Install only production dependencies
RUN yarn install --production --frozen-lockfile

# Copy built assets
COPY --from=build /app/dist ./dist

# Expose port used by "vite preview"
EXPOSE 4173

# Start Vite preview server
CMD ["yarn", "preview", "--host", "0.0.0.0"]
