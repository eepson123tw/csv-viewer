FROM node:22-alpine as build-stage

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install

# Copy project files
COPY . .

# Set environment variables for build time
ARG VITE_GOOGLE_CLIENT_ID
ARG VITE_GOOGLE_API_KEY
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ENV VITE_GOOGLE_API_KEY=$VITE_GOOGLE_API_KEY

# Build the app
RUN pnpm run build

# Production stage with Nginx
FROM nginx:stable-alpine as production-stage

# Configure Nginx with proper headers for Google authentication
RUN echo 'server {\
    listen       80;\
    server_name  localhost;\
    \
    location / {\
        add_header Cross-Origin-Opener-Policy same-origin-allow-popups;\
        root   /usr/share/nginx/html;\
        index  index.html index.htm;\
        try_files $uri $uri/ /index.html;\
    }\
}' > /etc/nginx/conf.d/default.conf

# Copy built files from build stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
