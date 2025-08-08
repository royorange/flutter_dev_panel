#!/bin/bash

echo "🧪 Testing GraphQL Integration..."
echo "================================"

# 进入示例项目目录
cd example

# 获取依赖
echo "📦 Getting dependencies..."
flutter pub get

# 运行测试
echo "🧪 Running GraphQL tests..."
flutter test test/graphql_test.dart

echo "✅ Tests completed!"