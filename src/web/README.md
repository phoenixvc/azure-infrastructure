# Web Frontend Template

Static web frontend templates for Azure Static Web Apps.

---

## Supported Frameworks

### **React**
```bash
npx create-react-app my-app
cd my-app
npm start
```

### **Next.js**
```bash
npx create-next-app@latest my-app
cd my-app
npm run dev
```

### **Vue.js**
```bash
npm create vue@latest my-app
cd my-app
npm install
npm run dev
```

---

## Project Structure

```
src/web/
├── public/              # Static assets
├── src/
│   ├── components/      # React/Vue components
│   ├── pages/           # Pages/routes
│   ├── styles/          # CSS/SCSS
│   └── utils/           # Utilities
├── package.json
├── tsconfig.json
└── staticwebapp.config.json  # SWA configuration
```

---

## Static Web App Configuration

Create `staticwebapp.config.json`:

```json
{
"routes": [
  {
    "route": "/api/*",
    "allowedRoles": ["authenticated"]
  },
  {
    "route": "/*",
    "serve": "/index.html",
    "statusCode": 200
  }
],
"navigationFallback": {
  "rewrite": "/index.html",
  "exclude": ["/images/*.{png,jpg,gif}", "/css/*"]
},
"responseOverrides": {
  "404": {
    "rewrite": "/404.html"
  }
},
"globalHeaders": {
  "content-security-policy": "default-src 'self'"
}
}
```

---

## Environment Variables

Create `.env.local`:

```bash
VITE_API_URL=https://nl-prod-rooivalk-api-euw.azurewebsites.net
VITE_APP_NAME=Rooivalk
```

---

## Build Configuration

### **React (Vite)**

```json
{
"scripts": {
  "dev": "vite",
  "build": "vite build",
  "preview": "vite preview"
}
}
```

Output: `dist/`

### **Next.js**

```json
{
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start"
}
}
```

Output: `out/` (with `next export`)

---

## Deployment

### **Via GitHub Actions (Automatic)**

Azure Static Web Apps automatically deploys on push to configured branch.

### **Manual Deployment**

```bash
# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Build
npm run build

# Deploy
swa deploy ./dist \
--deployment-token $DEPLOYMENT_TOKEN \
--env production
```

---

## Local Development with API

```bash
# Start SWA CLI with API
swa start ./dist --api-location ../functions
```

---

## Best Practices

- ✅ Use environment variables for configuration
- ✅ Implement proper error boundaries
- ✅ Add loading states
- ✅ Optimize images and assets
- ✅ Use code splitting
- ✅ Implement proper SEO (meta tags)
- ✅ Add analytics
- ✅ Configure CSP headers

---

## Example: React + TypeScript + Vite

```bash
# Create project
npm create vite@latest my-app -- --template react-ts
cd my-app

# Install dependencies
npm install

# Add SWA config
cat > public/staticwebapp.config.json << 'EOF'
{
"navigationFallback": {
  "rewrite": "/index.html"
}
}
EOF

# Build
npm run build

# Output: dist/
```

---

## Testing

```bash
# Install testing libraries
npm install -D @testing-library/react @testing-library/jest-dom vitest

# Run tests
npm test
```

---

## Related Resources

- [Azure Static Web Apps Documentation](https://learn.microsoft.com/azure/static-web-apps/)
- [SWA CLI](https://azure.github.io/static-web-apps-cli/)
- [Configuration Reference](https://learn.microsoft.com/azure/static-web-apps/configuration)
