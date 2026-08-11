# Push Order Flow to your GitHub repository

This repo is already created and populated for you at:
https://github.com/juttjathol/order-flow

## Later updates

When you make changes on your machine:

```bash
git clone https://github.com/juttjathol/order-flow.git
cd order-flow
# edit files
git add .
git commit -m "Your message"
git push
```

To release a new APK:

```bash
git tag v1.0.1
git push origin v1.0.1
```

GitHub Actions will build the APK and attach it to the Release. The Cloudflare dashboard will automatically show the download link.
