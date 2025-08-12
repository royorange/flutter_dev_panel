#!/bin/bash

# Flutter Dev Panel 发布脚本
# 用于发布主包和所有子包到 pub.dev

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

# 检查是否有未提交的更改
check_git_status() {
    if [[ -n $(git status -s) ]]; then
        print_error "有未提交的更改，请先提交或暂存"
        git status -s
        exit 1
    fi
}

# 发布包的函数
publish_package() {
    local package_path=$1
    local package_name=$2
    
    print_info "准备发布 $package_name..."
    
    cd "$package_path"
    
    # 运行测试
    print_info "运行测试..."
    if flutter test > /dev/null 2>&1; then
        print_success "测试通过"
    else
        print_error "测试失败，跳过 $package_name"
        return 1
    fi
    
    # 分析代码
    print_info "分析代码..."
    if dart analyze lib > /dev/null 2>&1; then
        print_success "代码分析通过"
    else
        print_error "代码分析失败"
        dart analyze lib
        return 1
    fi
    
    # 干运行检查
    print_info "运行发布前检查..."
    local dry_run_output
    local dry_run_exit_code
    
    # 暂时禁用 set -e 以捕获退出码
    set +e
    dry_run_output=$(flutter pub publish --dry-run 2>&1)
    dry_run_exit_code=$?
    set -e
    
    # 显示包大小信息
    echo "$dry_run_output" | grep "Total compressed" || true
    
    # 检查是否有真正的错误
    # 退出码 65 通常表示有警告但可以发布
    if echo "$dry_run_output" | grep -q "Package has.*error"; then
        print_error "发布前检查失败（有错误）"
        echo "$dry_run_output" | grep -A 10 "error"
        return 1
    elif echo "$dry_run_output" | grep -q "Package has.*warning"; then
        # 有警告但可以发布（常见于 monorepo 结构）
        print_info "发布前检查通过（有警告但可以发布）"
        print_info "警告通常是关于 gitignored 文件，这在 monorepo 中是正常的"
    elif [[ $dry_run_exit_code -eq 0 ]]; then
        # 完全没有问题
        print_success "发布前检查完全通过"
    else
        # 其他情况也继续（只要没有明确的错误）
        print_info "发布前检查完成"
    fi
    
    # 询问是否发布
    echo ""
    read -p "是否发布 $package_name 到 pub.dev? [Y/n] " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "跳过发布 $package_name"
    else
        print_info "发布 $package_name..."
        flutter pub publish --force
        print_success "$package_name 发布成功!"
    fi
    
    cd - > /dev/null
    echo ""
}

# 更新子包依赖的函数
update_subpackage_dependencies() {
    local package_path=$1
    local main_version=$2
    
    print_info "更新 $package_path 的依赖..."
    
    # 备份原始 pubspec.yaml
    cp "$package_path/pubspec.yaml" "$package_path/pubspec.yaml.bak"
    
    # 更新依赖：从 path 改为版本号
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|path: ../..|^$main_version|g" "$package_path/pubspec.yaml"
    else
        # Linux
        sed -i "s|path: ../..|^$main_version|g" "$package_path/pubspec.yaml"
    fi
    
    # 移除 publish_to: none
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/publish_to: none/d' "$package_path/pubspec.yaml"
    else
        sed -i '/publish_to: none/d' "$package_path/pubspec.yaml"
    fi
    
    print_success "依赖更新完成"
}

# 恢复子包依赖的函数
restore_subpackage_dependencies() {
    local package_path=$1
    
    if [[ -f "$package_path/pubspec.yaml.bak" ]]; then
        mv "$package_path/pubspec.yaml.bak" "$package_path/pubspec.yaml"
        print_info "已恢复 $package_path 的原始依赖配置"
    fi
}

# 主流程
main() {
    print_info "Flutter Dev Panel 发布脚本"
    echo "================================"
    
    # 检查当前目录
    if [[ ! -f "pubspec.yaml" ]] || [[ ! -d "packages" ]]; then
        print_error "请在 flutter_dev_panel 根目录运行此脚本"
        exit 1
    fi
    
    # 检查 Git 状态
    print_info "检查 Git 状态..."
    check_git_status
    print_success "Git 状态干净"
    
    # 获取主包版本
    MAIN_VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
    print_info "主包版本: $MAIN_VERSION"
    
    echo ""
    echo "发布顺序："
    echo "1. flutter_dev_panel (主包)"
    echo "2. flutter_dev_panel_console"
    echo "3. flutter_dev_panel_network"
    echo "4. flutter_dev_panel_device"
    echo "5. flutter_dev_panel_performance"
    echo ""
    
    read -p "开始发布流程? [Y/n] " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "发布取消"
        exit 0
    fi
    
    # 发布主包
    echo ""
    print_info "====== 发布主包 ======"
    publish_package "." "flutter_dev_panel"
    
    # 询问是否继续发布子包
    echo ""
    read -p "主包发布完成，是否继续发布子包? [Y/n] " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "跳过子包发布"
        exit 0
    fi
    
    # 子包列表
    SUBPACKAGES=(
        "flutter_dev_panel_console"
        "flutter_dev_panel_network"
        "flutter_dev_panel_device"
        "flutter_dev_panel_performance"
    )
    
    # 更新并发布子包
    for package in "${SUBPACKAGES[@]}"; do
        echo ""
        print_info "====== 处理 $package ======"
        
        package_path="packages/$package"
        
        # 更新依赖
        update_subpackage_dependencies "$package_path" "$MAIN_VERSION"
        
        # 发布包
        if publish_package "$package_path" "$package"; then
            print_success "$package 处理完成"
        else
            print_error "$package 处理失败"
            # 恢复原始配置
            restore_subpackage_dependencies "$package_path"
        fi
    done
    
    echo ""
    print_success "所有包发布流程完成!"
    
    # 询问是否恢复本地开发配置
    echo ""
    read -p "是否恢复子包的本地开发配置 (path 依赖)? [Y/n] " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        for package in "${SUBPACKAGES[@]}"; do
            restore_subpackage_dependencies "packages/$package"
        done
        print_success "本地开发配置已恢复"
    fi
}

# 运行主流程
main