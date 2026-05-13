#!/bin/bash
set -e

# version.json を現在日時で更新
VERSION=$(date +"%Y%m%d-%H%M")
echo "{ \"v\": \"$VERSION\" }" > version.json
echo "✅ version.json → $VERSION"

# GAS をデプロイ
echo "📤 clasp push..."
clasp push

echo "🚀 clasp deploy..."
clasp deploy -i AKfycbwx7XFQHALQSD7UMBsVXKdxqgH9yktleZOjV3HN-qStmlod8ifpNw6_FazO4-jI6mWiug

# GitHub Pages をデプロイ
echo "📤 git push..."
git add -A
git commit -m "deploy $VERSION"
git push origin main

echo "🎉 デプロイ完了: $VERSION"
