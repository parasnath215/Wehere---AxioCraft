FROM node:20-alpine

WORKDIR /app

# Install dependencies and openssl for Prisma
RUN apk add --no-cache openssl
COPY package*.json ./
RUN npm install

# Copy source
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Expose port
EXPOSE 4000

# Start server
CMD ["npm", "start"]
